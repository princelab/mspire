
require 'vec/r'

# Adapted from qvalue.R by Alan Dabney and John Storey which was LGPL licensed

class VecD
  Default_lambdas = []
  0.0.step(0.9,0.05) {|v| Default_lambdas << v }

  Default_q_values_args = {:pi_zero_tuning=>Default_lambdas, :pi_zero_method=>:smooth, :pi_zero_smooth_log_transform => false, :robust=>false, :smooth_df => 3, :fdr_level => nil}

  # returns the pi_zero estimate by taking the fraction of all p-values above
  # lambd and dividing by (1-lambd) and gauranteed to be <= 1
  def pi_zero_at_lambda(lambd)
    v = (self.select{|v| v >= lambd}.size.to_f/self.size) / (1 - lambd) 
    [v, 1].min
  end

  # returns a parallel array (VecI) of how many are <= in the array 
  # roughly: VecD[1,8,10,8,9,10].num_le => VecI[1, 3, 6, 3, 4, 6]
  def num_le
    hash = Hash.new {|h,k| h[k] = [] }
    self.each_with_index do |v,i|
      hash[v] << i
    end
    num_le_ar = []
    sorted = self.sort
    count = 0
    sorted.each_with_index do |v,i|
      back = 1
      count += 1
      if v == sorted[i-back]
        while (sorted[i-back] == v)
          num_le_ar[i-back] = count
          back -= 1 
        end
      else
        num_le_ar[i] = count
      end
    end
    ret = VecI.new(self.size)
    num_le_ar.zip(sorted) do |n,v|
      indices = hash[v]
      indices.each do |i|
        ret[i] = n
      end
    end
    ret
  end

  # assumes that vec is filled with p values
  # :pi_zero_method => :smooth or :bootstrap
  # :pi_zero_tuning => Float or Array of floats between 0 and 1 (at least 4)
  # :pi_zero_smooth_log_transform => true / false
  # :robuts => true / false
  # :smooth_df => Integer
  # :fdr_level => (0,1] or nil
  # Defaults taken from Default_q_values_args
  def q_values(args={}) 
    opts = Default_q_values_args.merge(args)
    p opts
    tun_arg = :pi_zero_tuning
    tuning = opts[:pi_zero_tuning]
    puts tuning.is_a?(Numeric)
    tuning_ar = if tuning.is_a?(Numeric)
                  [tuning]
                else
                  tuning
                end
    fdr_level = opts[:fdr_level]
    if !fdr_level.nil? && (fdr_level <= 0 || fdr_level > 1)
      raise ArgumentError, "fdr_level must be within (0,1]"
    end
    if tuning_ar.size != 1 && tuning_ar.size < 4
      raise ArgumentError, "#{tun_arg} must have 1 or 4 or more values"
    end
    if tuning_ar.any? {|v| v < 0 || v >= 1}
      raise ArgumentError, "#{tun_arg} vals must be within [0,1)"
    end
    if self.min < 0 || self.max > 1
      raise ArgumentError, "p-values must be within [0,1)"
    end

    pi_zeros = tuning_ar.map {|val| self.pi_zero_at_lambda(val) }
    pi_zero =
      if tuning_ar.size == 1
        pi_zeros.first
      else
        case opts[:pi_zero_method]
        when :smooth
          r = RSRuby.instance
          calc_pi_zero = lambda do |_pi_zeros| 
            hash = r.smooth_spline(tuning_ar, _pi_zeros, :df => opts[:smooth_df]) 
            puts "MAX INDEX"
            puts VecD.new(tuning_ar).max_indices.max
          end
          if opts[:pi_zero_smooth_log_transform]
            pi_zeros.log_space {|log_vals| calc_pi_zero.call(log_vals) }
          else
            calc_pi_zero.call(pi_zeros)
          end
        when :bootstrap
          raise NotImplementedError

          # to me, it looks like this bootstrapping method is pretty worthless
          # since it samples the SAME p-values over and over again!
          # (at least that's how I read the code)

          #  minpi0 <- min(pi0)
          #  mse <- rep(0,length(lambda))
          #  pi0.boot <- rep(0,length(lambda))
          #  for(i in 1:100) {
          #      # m = length(p) (i.e, self.size)
          #      p.boot <- sample(p,size=m,replace=TRUE) ## shuffles p values?
          #      for(i in 1:length(lambda)) {
          #          # mean(vec > x) === the fraction greater than x
          #          pi0.boot[i] <- mean(p.boot>lambda[i])/(1-lambda[i])
          #      }
          #      mse <- mse + (pi0.boot-minpi0)^2
          #  }
          #  pi0 <- min(pi0[mse==min(mse)])
          #  pi0 <- min(pi0,1)

        else 
          raise ArgumentError, ":pi_zero_method must be :smooth or :bootstrap!"
        end

      end
    raise RunTimeError, "pi0 <= 0 ... check your p-values!!" if pi_zero <= 0
    puts "HELLo"
    num_le_ar = self.num_le
    p num_le_ar
    qvalues = pi_zeros * pi_zeros.size * self / num_le_ar
    p qvalues

  end
end

=begin

#The estimated q-values calculated here
    u <- order(p)  # returns the indices that would order p

    # change by Alan
    # ranking function which returns number of observations less than or equal
    qvalue.rank <- function(x) {
      idx <- sort.list(x)

      fc <- factor(x)
      nl <- length(levels(fc))  # num of unique vals
      bin <- as.integer(fc)     # bins?
      tbl <- tabulate(bin)
      cs <- cumsum(tbl)
 
      tbl <- rep(cs, tbl)
      tbl[idx] <- tbl

      return(tbl)
    }

    v <- qvalue.rank(p)
    
    qvalue <- pi0*m*p/v
    if(robust) {
        qvalue <- pi0*m*p/(v*(1-(1-p)^m))
    }
    qvalue[u[m]] <- min(qvalue[u[m]],1)
    for(i in (m-1):1) {
    qvalue[u[i]] <- min(qvalue[u[i]],qvalue[u[i+1]],1)
    }
#The results are returned
    if(!is.null(fdr.level)) {
        retval <- list(call=match.call(), pi0=pi0, qvalues=qvalue, pvalues=p, fdr.level=fdr.level, ## change by Alan
          significant=(qvalue <= fdr.level), lambda=lambda)
    }
    else {
        retval <- list(call=match.call(), pi0=pi0, qvalues=qvalue, pvalues=p, lambda=lambda)
    }
    class(retval) <- "qvalue"
    return(retval)
}

qplot <- function(qobj, rng=c(0.0, 0.1), smooth.df = 3, smooth.log.pi0 = FALSE, ...) { ## change by Alan:  
##  'rng' a vector instead of an upper bound alone
#Input
#=============================================================================
#qobj: a q-value object returned by the qvalue function
#rng: the range of q-values to be plotted (optional)
#smooth.df: degrees of freedom to use in smoother (optional)
#smooth.log.pi0: should smoothing be done on log scale? (optional)
#
#Output
#=============================================================================
#Four plots:
#Upper-left: pi0.hat(lambda) versus lambda with a smoother
#Upper-right: q-values versus p-values
#Lower-left: number of significant tests per each q-value cut-off
#Lower-right: number of expected false positives versus number of significant tests
##library(stats) ## change by Alan:  'stats' automatically loaded
q2 <- qobj$qval[order(qobj$pval)]
if(min(q2) > rng[2]) {rng <- c(min(q2), quantile(q2, 0.1))} ## change by Alan:  replace 'rng' with vector
p2 <- qobj$pval[order(qobj$pval)]
par(mfrow=c(2,2))
lambda <- qobj$lambda
if(length(lambda)==1) {lambda <- seq(0,max(0.90,lambda),0.05)}
pi0 <- rep(0,length(lambda))
for(i in 1:length(lambda)) {
    pi0[i] <- mean(p2>lambda[i])/(1-lambda[i])
    }
    
if(smooth.log.pi0)
  pi0 <- log(pi0)
spi0 <- smooth.spline(lambda,pi0,df=smooth.df)

if(smooth.log.pi0) {
  pi0 <- exp(pi0)
  spi0$y <- exp(spi0$y)
}

pi00 <- round(qobj$pi0,3)
plot(lambda,pi0,xlab=expression(lambda),ylab=expression(hat(pi)[0](lambda)),pch=".")
mtext(substitute(hat(pi)[0] == that, list(that= pi00)))
lines(spi0)

plot(p2[q2 >= rng[1] & q2 <= rng[2]], q2[q2 >= rng[1] & q2 <= rng[2]], type = "l", xlab = "p-value", ## changes by Alan
  ylab = "q-value")
plot(q2[q2 >= rng[1] & q2 <= rng[2]], (1 + sum(q2 < rng[1])):sum(q2 <= rng[2]), type="l",
  xlab="q-value cut-off", ylab="significant tests")
plot((1 + sum(q2 < rng[1])):sum(q2 <= rng[2]), q2[q2 >= rng[1] & q2 <= rng[2]] *
  (1 + sum(q2 < rng[1])):sum(q2 <= rng[2]), type = "l", xlab = "significant tests",
  ylab = "expected false positives")
par(mfrow=c(1,1))
}

plot.qvalue <- function(x, ...) qplot(x, ...)

qwrite <- function(qobj, filename="my-qvalue-results.txt") {
#Input
#=============================================================================
#qobj: a q-value object returned by the qvalue function
#filename: the name of the file where the results are written
#
#Output
#=============================================================================
#A file sent to "filename" with the following:
#First row: the estimate of the proportion of true negatives, pi0
#Second row: FDR significance level (if specified) ## change by Alan
#Third row and below: the p-values (1st column), the estimated q-values (2nd column),
#  and indicator of significance level if appropriate (3rd column)
  cat(c("pi0:", qobj$pi0, "\n\n"), file=filename, append=FALSE)
  if(any(names(qobj) == "fdr.level")) {
    cat(c("FDR level:", qobj$fdr.level, "\n\n"), file=filename, append=TRUE)
    cat(c("p-value q-value significant", "\n"), file=filename, append=TRUE) ## change by Alan (space-delimited now)
#    for(i in 1:length(qobj$qval)) {
#      cat(c(qobj$pval[i], "\t", qobj$qval[i], "\t", qobj$significant[i], "\n"), file=filename, append=TRUE)
#    }
    write(t(cbind(qobj$pval, qobj$qval, qobj$significant)), file=filename, ncolumns=3, append=TRUE) ## change by Alan
  }
  else {
    cat(c("p-value q-value", "\n"), file=filename, append=TRUE)
#    for(i in 1:length(qobj$qval)) {
#      cat(c(qobj$pval[i], "\t", qobj$qval[i], "\n"), file=filename, append=TRUE)
#    }
    write(t(cbind(qobj$pval, qobj$qval)), file=filename, ncolumns=2, append=TRUE)
  }
}

qsummary <- function (qobj, cuts=c(0.0001, 0.001, 0.01, 0.025, 0.05, 0.10, 1), digits=getOption("digits"), ...) {
  cat("\nCall:\n", deparse(qobj$call), "\n\n", sep = "")
  cat("pi0:",format(qobj$pi0, digits=digits),"\n", sep="\t")
  cat("\n")
  cat("Cumulative number of significant calls:\n")
  cat("\n")
  counts <- sapply(cuts, function(x) c("p-value"=sum(qobj$pvalues < x), "q-value"=sum(qobj$qvalues < x)))
  colnames(counts) <- paste("<", cuts, sep="")
  print(counts)
  cat("\n")
  invisible(qobj)
}

summary.qvalue <- function(object, ...) {
  qsummary(object, ...)
}

####################################################
## TCL-TK GUI for John Storey's Q-Value Software. ##
## Alan Dabney, 10/01/03                          ##
####################################################

qvalue.gui <- function(dummy = NULL) {

  if(interactive()) {

  require(tcltk) || stop("TCLTK support is absent.")

  out <- NULL
  inFileName.var <- tclVar("")
  pp <- NULL
  from.var.1 = tclVar("0.0")
  to.var.1 = tclVar("0.90")
  by.var.1 = tclVar("0.05")
  from.var.2 = tclVar("0.0")
  to.var.2 = tclVar("0.1")
  single.var = tclVar("")
  lambda.var = tclVar(1)
  pi0.var = tclVar(1)
  df.var = tclVar("3")
  log.no.var = tclVar(1)
   
  robust.var = tclVar(0)
  levelSpec.var = tclVar(0)
  level.var = tclVar("0.05")
  plotChoice.var = tclVar(1)

  titleFont <- "Helvetica 14"
  normalFont <- "Helvetica 10"

  ########################
  ## Utility functions  ##
  ########################

  findPVals <- function() {
    tclvalue(inFileName.var) <- tclvalue(tkgetOpenFile())
  }

  readPVals <- function() {
    flnm <- tclvalue(inFileName.var)

    if(flnm == "") {
      postMsg("ERROR: No file selected.\n")
    }

    else {
      postMsg("Reading p-values...")
      pvals = scan(flnm)
      if(is.null(pvals) == FALSE) {
        assign("pp", pvals, inherits = TRUE)
        postMsg("done.\n")
      }
    }
  }

  lambda.fnc <- function() {
    if(tclvalue(lambda.var) == 1) {
      tkconfigure(from.ety.1, state = "normal")
      tkconfigure(to.ety.1, state = "normal")
      tkconfigure(by.ety.1, state = "normal")
      tkconfigure(single.ety, state = "disabled")
    }
    else {
      tkconfigure(from.ety.1, state = "disabled")
      tkconfigure(to.ety.1, state = "disabled")
      tkconfigure(by.ety.1, state = "disabled")
      tkconfigure(single.ety, state = "normal")
    }
  }

  smoother.fnc <- function() {
    if(tclvalue(pi0.var) == 1)
      tkconfigure(smoothOptions.btn, state = "normal")
    else
      tkconfigure(smoothOptions.btn, state = "disabled")
  }
  
  smoothOptions.fnc <- function() {
    base <- tktoplevel()
    tkwm.title(base, "Smoother")

    df.var.0 <- tclvalue(df.var)
    log.no.var.0 <- tclvalue(log.no.var)

    smooth.ok.fnc <- function() {
      tkdestroy(base)
    }
    
    smooth.cancel.fnc <- function() {
      tclvalue(df.var) <- df.var.0
      tclvalue(log.no.var) <- log.no.var.0
      
      tkdestroy(base)
    }
    
    top.frm <- tkframe(base, borderwidth = 2)
    inset.frm <- tkframe(top.frm, relief = "raised", bd = 2)
    
    df.frm <- tkframe(inset.frm)
    df.lbl <- tklabel(df.frm, text = "Degrees of freedom:", font = normalFont)
    df.ety <- tkentry(df.frm, textvariable = df.var, font = normalFont, width = 3, justify = "center")
    tkpack(df.lbl, side = "left")
    tkpack(df.ety, side = "left")
    
    log.lbl.frm <- tkframe(inset.frm)
    log.lbl <- tklabel(log.lbl.frm, text = "Variable to smooth:", font = normalFont)
    tkpack(log.lbl, side = "left")

    log.no.frm <- tkframe(inset.frm)
    log.no.cbtn <- tkradiobutton(log.no.frm, text = "pi0", font = normalFont, 
      variable = log.no.var, value = 1)
    tkpack(log.no.cbtn, side = "left")

    log.yes.frm <- tkframe(inset.frm)
    log.yes.cbtn <- tkradiobutton(log.yes.frm, text = "log pi0", font = normalFont, 
      variable = log.no.var, value = 0)
    tkpack(log.yes.cbtn, side = "left")
    
    btn.frm <- tkframe(inset.frm)
    ok.btn <- tkbutton(btn.frm, text = "OK", font = normalFont, command = smooth.ok.fnc)
    cancel.btn <- tkbutton(btn.frm, text = "Cancel", font = normalFont, command = smooth.cancel.fnc)
    tkgrid(ok.btn, cancel.btn)
    
    tkpack(df.frm, padx = 5, anchor = "w", fill = "x", expand = TRUE)
    tkpack(log.lbl.frm, padx = 5, anchor = "w", fill = "x", expand = TRUE)
    tkpack(log.no.frm, padx = 10, anchor = "w", fill = "x", expand = TRUE)
    tkpack(log.yes.frm, padx = 10, anchor = "w", fill = "x", expand = TRUE)
    tkpack(btn.frm, anchor = "e")
    tkpack(inset.frm)
    tkpack(top.frm)
  }

  level.fnc <- function() {
    if(tclvalue(levelSpec.var) == 1)
      tkconfigure(level.ety, state = "normal")
    else
      tkconfigure(level.ety, state = "disabled")
  }

  execute.fnc <- function() {
    if(is.null(pp))
      postMsg("ERROR: P-values haven't been read yet.\n")

    else {
      postMsg("Computing q-values...")
      if(tclvalue(lambda.var) == 1)
        lambda <- seq(from = as.numeric(tclvalue(from.var.1)), to = as.numeric(tclvalue(to.var.1)),
          by = as.numeric(tclvalue(by.var.1)))
      else {
        lambda <- as.numeric(tclvalue(single.var))
        if(is.na(lambda)) {
          postMsg("ERROR: Please specify value for lambda.\n")
          return()
        }
#        else if(lambda <= 0.0 || lambda >= 1.0) {
#          postMsg("ERROR: Lambda must be between 0.0 and 1.0.\n")
#          return()
#        }
      }
      if(tclvalue(pi0.var) == 1)
        pi0.method <- "smoother"
      else
        pi0.method <- "bootstrap"
      if(tclvalue(levelSpec.var) == 1) {
        fdr.level <- as.numeric(tclvalue(level.var))
        if(is.na(fdr.level)) {
          postMsg("ERROR: Please specify FDR level.\n")
          return()
        }
#        else if(fdr.level <= 0.0 || fdr.level >= 1.0) {
#          postMsg("aborted.\n")
#          postMsg("FDR level must be between 0.0 and 1.0.\n")
#          return()
#        }
      }
      else
        fdr.level <- NULL
      if(tclvalue(robust.var) == 1)
        robust <- TRUE
      else
        robust <- FALSE
      if(tclvalue(log.no.var) == 1)
        smooth.log.pi0 = TRUE
      else
        smooth.log.pi0 = FALSE

      qout = qvalue(p = pp, lambda = lambda, pi0.method = pi0.method, fdr.level = fdr.level,
        robust = robust, gui = TRUE, smooth.df = as.numeric(tclvalue(df.var)), smooth.log.pi0 = smooth.log.pi0)
      if(class(qout) == "qvalue") {
        tclvalue(to.var.2) = as.character(round(qout$pi0, 4))
        assign("out", qout, inherits = TRUE)
        postMsg(paste("done: pi_0 = ", round(qout$pi0, 4), ".\n", sep = ""))
      }
    }
  }

  plotChoice.fnc <- function() {
    if(tclvalue(plotChoice.var) == 1 | tclvalue(plotChoice.var) == 2) {
      tkconfigure(from.ety.2, state = "disabled")
      tkconfigure(to.ety.2, state = "disabled")
    }
    else {
      tkconfigure(from.ety.2, state = "normal")
      tkconfigure(to.ety.2, state = "normal")
    }
  }

  histPVals <- function() {
    if(is.null(pp))
      postMsg("ERROR: P-values haven't been read yet.\n")

    else {
      par(mfrow = c(1, 1))
      hist(pp, main = "Histogram of P-Values")
    }
  }


  plot.fnc <- function() {
    if(tclvalue(plotChoice.var) == 1) {
      if(is.null(pp))
        postMsg("ERROR: P-values haven't been read yet.\n")

      else {
        par(mfrow = c(1, 1))
        hist(pp, main = "Histogram of P-Values", xlab = "")
      }
    }

    else if(tclvalue(plotChoice.var) == 2) {
      if(is.null(out))
        postMsg("ERROR: Q-values haven't been computed yet.\n")
      else if(class(out) == "qvalue") {
        par(mfrow = c(1, 1))
        hist(out$qvalues, main = "Histogram of Q-Values", xlab = "")
      }
    }

    else {
      if(tclvalue(log.no.var) == 1)
        smooth.log.pi0 = TRUE
      else
        smooth.log.pi0 = FALSE
    
      if(is.null(out))
        postMsg("ERROR: Q-values haven't been computed yet.\n")        
      else if(class(out) == "qvalue")
        qplot(out, rng = as.numeric(c(tclvalue(from.var.2), tclvalue(to.var.2))), 
            smooth.df = as.numeric(tclvalue(df.var)), smooth.log.pi0 = smooth.log.pi0)
    }
  }

  saveOutput.fnc <- function() {
    if(is.null(out))
      postMsg("ERROR: Q-values haven't been computed yet.\n")

    else if(class(out) == "qvalue") {
      postMsg("Writing results to file...")
      flnm <- tclvalue(tkgetSaveFile())
      if(flnm != "") {
        qwrite(out, filename = flnm)
        postMsg("done.\n")
      }
      else
        postMsg("aborted.\n")
    }
  }

  savePlot.fnc <- function() {
    if(tclvalue(plotChoice.var) == 1) {
      if(is.null(pp))
        postMsg("ERROR: P-values haven't been read yet.\n")
      else {
        flnm <- tclvalue(tkgetSaveFile(defaultextension = "pdf", filetypes = "{{PDF File} {.pdf}}"))
        if(flnm != "") {
          pdf(flnm)
          par(mfrow = c(1, 1))
          hist(pp, main = "Histogram of P-Values", xlab = "")
          dev.off()
          postMsg("Plot saved.\n")
        }
        else
          postMsg("No file selected.  Plot not saved.\n")
      }
    }

    else if(tclvalue(plotChoice.var) == 2) {
      if(is.null(out))
        postMsg("ERROR: Q-values haven't been computed yet.\n")
      else if(class(out) == "qvalue") {
        flnm <- tclvalue(tkgetSaveFile(defaultextension = "pdf"))
        if(flnm != "") {
          pdf(flnm)
          par(mfrow = c(1, 1))
          hist(out$qvalues, main = "Histogram of Q-Values", xlab = "")
          dev.off()
          postMsg("Plot saved.\n")
        }
        else
          postMsg("No file selected.  Plot not saved.\n")
      }
    }

    else {
      if(is.null(out))
        postMsg("ERROR: Q-values haven't been computed yet.\n")
      else if(class(out) == "qvalue") {
        flnm <- tclvalue(tkgetSaveFile(defaultextension = "pdf"))
        if(flnm != "") {
          pdf(flnm)
          qplot(out, rng = as.numeric(c(tclvalue(from.var.2), tclvalue(to.var.2))))
          dev.off()
          postMsg("Plot saved.\n")
        }
        else
          postMsg("No file selected.  Plot not saved.\n")
      }
    }
  }

  postMsg <- function(msg) {
    tkconfigure(message.txt, state = "normal")
    tkinsert(message.txt, "end", msg)
    tkconfigure(message.txt, state = "disabled")
  }

  errorHandler <- function() {
    postMsg(paste("An R error has occurred: ", geterrmessage(), sep = ""))
  }

  ## Reroute R errors to the message box
  options(error = errorHandler, show.error.messages = FALSE)

  ##############
  ## GUI code ##
  ##############

  ## Top level
  base <- tktoplevel()
  tkwm.title(base, "QVALUE")

  top.frm <- tkframe(base, borderwidth = 2)

  ## P-Value frame contains text field, browse button, load button, histogram button.
  pValue.frm <- tkframe(top.frm, relief = "raised", bd = 2)
  tkpack(tklabel(pValue.frm, text = "Read P-Values:", font = titleFont), anchor = "w")
  pValueInset.frm <- tkframe(pValue.frm, relief = "groove", bd = 2)

  inFileName.frm <- tkframe(pValueInset.frm)
  inFileName.lbl <- tklabel(inFileName.frm, text = "File Name:", font = normalFont)
  inFileName.ety <- tkentry(inFileName.frm, textvariable = inFileName.var, font = normalFont, 
    justify = "center")
  tkpack(inFileName.lbl, side = "left")
  tkpack(inFileName.ety, side = "right", fill = "x", expand = TRUE)
  tkpack(inFileName.frm, fill = "x", expand = TRUE)

  pButtons.frm <- tkframe(pValueInset.frm)
  browse.btn <- tkbutton(pButtons.frm, text = "Browse", font = normalFont, command = findPVals)
  load.btn <- tkbutton(pButtons.frm, text = "Load", font = normalFont, command = readPVals)
  tkgrid(browse.btn, load.btn)
  tkpack(pButtons.frm, anchor = "e")
  tkpack(pValueInset.frm, fill = "x")

  ## Options frame allows user to specify lambda and pi_0 estimation method.
  options.frm <- tkframe(top.frm, relief = "raised", bd = 2)
  tkpack(tklabel(options.frm, text = "Optional Arguments:", font = titleFont), anchor = "w")
  optionsInset.frm <- tkframe(options.frm, relief = "groove", bd = 2)

  #### Specify lambda
  lambdaLabel.frm <- tkframe(optionsInset.frm)
  tkpack(tklabel(lambdaLabel.frm, text = "Specify lambda:", font = normalFont), anchor = "w")
  tkpack(lambdaLabel.frm, fill = "x", expand = TRUE)

  lambdaRange.frm <- tkframe(optionsInset.frm, padx = 10)
  range.rbtn <- tkradiobutton(lambdaRange.frm, text = "Range", font = normalFont, value = 1,
    variable = lambda.var, command = lambda.fnc)
  from.lbl.1 <- tklabel(lambdaRange.frm, text = "from:", font = normalFont)
  to.lbl.1 <- tklabel(lambdaRange.frm, text = "to:", font = normalFont)
  by.lbl.1 <- tklabel(lambdaRange.frm, text = "by:", font = normalFont)
  from.ety.1 <- tkentry(lambdaRange.frm, textvariable = from.var.1, font = normalFont, width = 5, 
    justify = "center")
  to.ety.1 <- tkentry(lambdaRange.frm, textvariable = to.var.1, font = normalFont, width = 5, 
    justify = "center")
  by.ety.1 <- tkentry(lambdaRange.frm, textvariable = by.var.1, font = normalFont, width = 5, 
    justify = "center")
  tkpack(range.rbtn, side = "left", anchor = "w")
  tkpack(from.lbl.1, side = "left")
  tkpack(from.ety.1, side = "left")
  tkpack(to.lbl.1, side = "left")
  tkpack(to.ety.1, side = "left")
  tkpack(by.lbl.1, side = "left")
  tkpack(by.ety.1, side = "left")
  tkpack(lambdaRange.frm, fill = "x", expand = TRUE)

  lambdaSingle.frm <- tkframe(optionsInset.frm, padx = 10)
  single.rbtn <- tkradiobutton(lambdaSingle.frm, text = "Single No.:", font = normalFont, value = 0,
    variable = lambda.var, command = lambda.fnc)
  single.ety <- tkentry(lambdaSingle.frm, textvariable = single.var, font = normalFont, width = 5,
    state = "disabled", justify = "center")
  tkpack(single.rbtn, side = "left", anchor = "w")
  tkpack(single.ety, side = "left")
  tkpack(lambdaSingle.frm, fill = "x", expand = TRUE)

  #### Specify bootstrap or smoother method
  methodLabel.frm <- tkframe(optionsInset.frm)
  tkpack(tklabel(methodLabel.frm, text = "Choose pi_0 method:", font = normalFont), anchor = "w")
  tkpack(methodLabel.frm, fill = "x", expand = TRUE)

  methodSmooth.frm <- tkframe(optionsInset.frm, padx = 10)
  smoother.rbtn <- tkradiobutton(methodSmooth.frm, text = "Smoother", font = normalFont, value = 1, 
    variable = pi0.var, command = smoother.fnc)
  smoothOptions.btn <- tkbutton(methodSmooth.frm, text = "Advanced Options", font = normalFont, 
    command = smoothOptions.fnc)
  tkpack(smoother.rbtn, side = "left", anchor = "w")
  tkpack(smoothOptions.btn, side = "left")
  tkpack(methodSmooth.frm, fill = "x", expand = TRUE)
  
  methodBstrap.frm <- tkframe(optionsInset.frm, padx = 10)
  bootstrap.rbtn <- tkradiobutton(methodBstrap.frm, text = "Bootstrap", font = normalFont, value = 0, 
    variable = pi0.var, command = smoother.fnc)
  tkpack(bootstrap.rbtn, side = "left", anchor = "w")
  tkpack(methodBstrap.frm, fill = "x", expand = TRUE)

  #### Specify robust method
  robust.frm <- tkframe(optionsInset.frm)
  robust.cbtn <- tkcheckbutton(robust.frm, text = "Use robust method", font = normalFont,
    variable = robust.var)
  tkpack(robust.cbtn, anchor = "w")
  tkpack(robust.frm, fill = "x", expand = TRUE)

  #### Specify FDR level
  level.frm <- tkframe(optionsInset.frm)
  level.cbtn <- tkcheckbutton(level.frm, text = "Specify FDR level:", font = normalFont,
    variable = levelSpec.var, command = level.fnc)
  level.ety <- tkentry(level.frm, textvariable = level.var, font = normalFont, width = 5,
    state = "disabled", justify = "center")
  tkpack(level.cbtn, side = "left", anchor = "w")
  tkpack(level.ety, side = "left")
  tkpack(level.frm, fill = "x", expand = TRUE)
  tkpack(optionsInset.frm, fill = "x", expand = TRUE)

  ## Action frame
  action.frm <- tkframe(top.frm, relief = "raised", bd = 2)
  tkpack(tklabel(action.frm, text = "Compute Q-Values:", font = titleFont), anchor = "w")
  actionInset.frm <- tkframe(action.frm, relief = "groove", bd = 2)

  execute.btn <- tkbutton(actionInset.frm, text = "Execute", font = normalFont,
    command = execute.fnc)
  saveOutput.btn <- tkbutton(actionInset.frm, text = "Save Output", font = normalFont,
    command = saveOutput.fnc)
  tkpack(saveOutput.btn, side = "right", anchor = "e") ## padx argument here spreads buttons out
  tkpack(execute.btn, side = "right")
  tkpack(actionInset.frm, fill = "x", expand = TRUE)

  ## Plot frame
  plot.frm <- tkframe(top.frm, relief = "raised", bd = 2)
  tkpack(tklabel(plot.frm, text = "Plots:", font = titleFont), anchor = "w")
  plotInset.frm <- tkframe(plot.frm, relief = "groove", bd = 2)

  pHist.frm <- tkframe(plotInset.frm, padx = 10)
  pHist.rbtn <- tkradiobutton(pHist.frm, text = "P-value histogram", font = normalFont, value = 1,
    variable = plotChoice.var, command = plotChoice.fnc)
  tkpack(pHist.rbtn, side = "left", anchor = "w")
  tkpack(pHist.frm, fill = "x", expand = TRUE)

  qHist.frm <- tkframe(plotInset.frm, padx = 10)
  qHist.rbtn <- tkradiobutton(qHist.frm, text = "Q-value histogram", font = normalFont, value = 2,
    variable = plotChoice.var, command = plotChoice.fnc)
  tkpack(qHist.rbtn, side = "left", anchor = "w")
  tkpack(qHist.frm, fill = "x", expand = TRUE)

  qPlots.frm <- tkframe(plotInset.frm, padx = 10)
  qPlots.rbtn <- tkradiobutton(qPlots.frm, text = "Q-plots,", font = normalFont, value = 3,
    variable = plotChoice.var, command = plotChoice.fnc)
  from.lbl.2 <- tklabel(qPlots.frm, text = "range from:", font = normalFont)
  to.lbl.2 <- tklabel(qPlots.frm, text = "to:", font = normalFont)
  from.ety.2 <- tkentry(qPlots.frm, textvariable = from.var.2, font = normalFont, width = 7,
    state = "disabled", justify = "center")
  to.ety.2 <- tkentry(qPlots.frm, textvariable = to.var.2, font = normalFont, width = 7,
    state = "disabled", justify = "center")
  tkpack(qPlots.rbtn, side = "left", anchor = "w")
  tkpack(from.lbl.2, side = "left")
  tkpack(from.ety.2, side = "left")
  tkpack(to.lbl.2, side = "left")
  tkpack(to.ety.2, side = "left")
  tkpack(qPlots.frm, fill = "x", expand = TRUE)

  plot.btn <- tkbutton(plotInset.frm, text = "Make Plot", font = normalFont, command = plot.fnc)
  savePlot.btn <- tkbutton(plotInset.frm, text = "Save Plot to PDF", font = normalFont, command = savePlot.fnc)
  tkpack(savePlot.btn, side = "right", anchor = "e")
  tkpack(plot.btn, side = "right")
  tkpack(plotInset.frm, fill = "x", expand = TRUE)

  ## Message box
  message.frm <- tkframe(top.frm, relief = "raised", bd = 2)
  message.txt <- tktext(message.frm, bg = "white", font = normalFont, height = 5, width = 5)
  message.scr <- tkscrollbar(message.frm, command = function(...) tkyview(message.txt, ...))
  tkconfigure(message.txt, yscrollcommand = function(...) tkset(message.scr, ...))
  tkpack(message.txt, side = "left", fill = "x", expand = TRUE)
  tkpack(message.scr, side = "right", fill = "y")

  tkpack(pValue.frm, fill = "x")
  tkpack(options.frm, fill = "x")
  tkpack(action.frm, fill = "x")
  tkpack(plot.frm, fill = "x")
  tkpack(message.frm, fill = "x")
  tkpack(top.frm)

  tkwm.focusmodel(base, "active")

  }

}

.First.lib <- function (libname, pkgname, where) {
  library(stats)
}

=end
