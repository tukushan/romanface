pep <- function(expr) {
	## Parse then evaluate a character vector (expr), returning AND printing the
	## result if the result is visible (ie: the REP parts of the REPL).
	pcpr(expr)
}

.pep <- function(expr) {
	## Parse then evaluate a character vector (expr), returning AND printing the
	## result if the result is visible (ie: the REP parts of the REPL).
	## Modelled on the source() function.
	## Syntax errors will be produced by the parse function and result in 
	## none of the code being executed.
	## Evaluation errors will be produced by the eval.with.vis function and 
	## will cause execution to stop and the rest of the expression will not 
	## be executed. Anything assigned into the workspace by code that has 
	## been run will be kept.
	## Warnings are explicitly trapped and printed, because JRI doesn't
	## output them to the console when options(warn = 0) for expressions 
	## evaluated via calls to parseAndEval. 
	## Errors are not suppressed by JRI and output straight to the console.
	## NB: warnings are printed at the end of the evaluation of all lines
	## in the expr, as opposed to after each line as it's executed.
	## NB: because warnings are muffled, last.warning won't contain any
	## warnings generated by expr
	## NB: traceback() won't work on commands executed this way
	## if a function mutes warnings, then the will still be caught and
	## displayed

	localWarnings <- list()
	
	#wrap in try so if it errors this function will continue to execute 
	#and print any warnings
	result <- 
				# return invisible object of class "try-error" containing the 
				# error message if it fails. error message also goes to the
				# console
				try(
					withCallingHandlers(
						#evaluate in R_GlobalEnv and return R_visible flag
						withVisible(eval(parse(text = expr), .GlobalEnv, baseenv())),
					
						## trap and record warning in localWarnings list
						warning = function(w) {
							## because w$call can be NULL, we must wrap in list()
							## as per R FAQ 7.1
							localWarnings[length(localWarnings)+1] <<- list(w$call)
							names(localWarnings)[length(localWarnings)] <<- w$message
							
			 				## don't print warning to console
							invokeRestart("muffleWarning")  
						}
					)
				)
			
	if (!is(result,"try-error") && result$visible) {
		## print result if visible
		show(result$value)
	}
	
	if (length(localWarnings) > 0) {
		## explicitly print warnings if they exist
		show(structure(localWarnings, class = "warnings"))
	}
	
	## return value
	if (!is(result,"try-error")) {
		result$value
	}
}

.getObjects <- function (include = "all", exclude = "function") 
{
	#.getObjects() #show all except functions
	#.getObjects(exclude="") #show all including functions
	#.getObjects(c("data.frame","numeric") #show only dataframes and numeric vec
	#get a list of all the objects in the 
	#global environment, their class and their info
	#if showFunctions == TRUE returns functions as well
	objs <- ls(".GlobalEnv")
	klass <- sapply(objs, function(X) { class(get(X)) })
	klass <- .filter(klass, include, exclude)
	
	result <- NULL
	result$names <- names(klass)
	result$class <- klass
	result$info <- sapply(result$names, function(X) { .getInfo(get(X)) })
	
	names(result$class) <- NULL
	names(result$info) <- NULL
    result
}

.filter <- function (vec, include = "all", exclude = "function") {
	#.filter(c("a","b","c"), c("c","a"))
	vec[.filteredIndices(vec,include,exclude)]
}

.filteredIndices <- function (vec, include = "all", exclude = "function") {
	#.filteredIndices(c("a","b","c"), c("c","a"))
	if (any(include != "all")) {
		vec %in% include
	} else {
		!vec %in% exclude
	}
}

.getParts <- function (o, include = "all", exclude = "function") 
{
	#.getParts(o)
	#.getParts(o, "integer")
	#.getParts(o, "logical")
	#.getParts(c(1,2,3))
	#get a list containing the names, class, and info
	#about the parts of an object
	#if the object has no parts (or all parts are filtered out), returns NULL
    result <- NULL
    
    if (class(o) == "matrix" || (class(o) == "table" && length(dim(o)) == 2)) {
    	#matrix (ie: 2d array) and 2d tables
    	klass <- apply(o, 2, class)

        if (is.null(names(klass))) {
        	#unnamed, so give it some names
        	names(klass) <- .getPartNames(o[1,])
    	}

    	#just test first class because the rest will be the same
    	#since this is a matrix/table
    	if(.filteredIndices(klass[1], include, exclude)) {
			result$names <- names(klass)
			result$class <- klass
			result$info <- apply(o, 2, .getInfo)
		}
    	
    } else if (mode(o) == "list") {
    	#lists and dataframes
    	
        klass <- sapply(o, class)
        
        if (is.null(names(klass))) {
        	#unnamed, so give it some names
        	names(klass) <- .getPartNames(o)
    	}
    	
    	#filter out elements based on class
		selection <- .filteredIndices(klass, include, exclude)
		ofiltered <- o[selection]
		klassf <- klass[selection]
		
		#if we have any elements
		if (length(ofiltered) > 1) {
			result$names <- names(klassf)
			result$class <- klassf
	
			result$info <- sapply(ofiltered, .getInfo)
		}
    }

	names(result$class) <- NULL
	names(result$info) <- NULL
    result
}

.getPartNames <- function (o) {
	#.getPartNames(children)
	#.getPartNames(children$accom)
	#.getPartNames(array(c(1),c(2,2))[1,])
	resultNames <- c()
	#if o has no names, then use number index as a name
	if (!is.null(o) && is.null(names(o))) {
		if (mode(o) == "list") {
			#lists and dataframes
			resultNames <- paste("[[", c(1:length(o)), "]]", sep="")
		} else {
			#matrix (ie: 2d array) and 2d tables
			resultNames <- paste("[,", c(1:length(o)), "]", sep="")
		}
	}  else {
		resultNames <- names(o)
	}
	resultNames
}

.getInfo <- function (o) {
	#.getInfo(obj)
	#returns information about an object, or empty chr ""
	#if there is no information
	result <- c("")

	if (class(o) == "data.frame") {
		result  <- paste(class(o), " ", dim(o)[1], " obs. ", dim(o)[2], " vars", sep="")
	} else if (class(o) == "matrix") {
		result <- paste(class(o), " ", dim(o)[1], " x ", dim(o)[2], sep="")
	} else if (class(o) == "table") {
		if (length(dim(o)) == 2)
			result <- paste(class(o), " ", dim(o)[1], " x ", dim(o)[2], sep="")
		else if (length(dim(o)) == 1)
			result <- paste(class(o), " 1 x ", dim(o), sep="")
		else
			result <- paste(class(o), " ",length(o), sep="")
	} else if (class(o) == "list") {
		result <- paste(class(o), " ",length(o), sep="")
	} else if (class(o) == "function") {
		result <- class(o)
	} else {
		result <- paste(class(o), " ",length(o), sep="")
	}
	
	result
}

# PCPR (parse, capture all, print, return) functions for REPL imitation
# ---------------------------------------------------------------------

pcpr <- function (stringExpr) {
	#pcr - parse, capture all, return 
	#based on svMisc::captureAll
	#takes a character string and parses and then evaluates it, 
	#reproducing the evaluation console output the same way as it 
	#would be done in a R console, and returns the value of the
	#last executed statement
	
	#override the warning function in TempEnv()
	assign("warning", .warningOverride, envir = TempEnv())
	
	on.exit({
				if (exists("warning", envir = TempEnv())) rm("warning", 
							envir = TempEnv())
			})
	
	#main evaluation loop
	#evaluate each statement in the expression individually one at a time
	tmp <- NULL
	parsedExpr <- parseTxt(stringExpr)
	for (i in 1:length(parsedExpr)) {
		tmp <- .evalVis(parsedExpr[[i]])
		
		#check for error
		if (inherits(tmp, "try-error")) {
			
			#set last.warning to the "last.warning" attribute of tmp
			last.warning <- attr(tmp, "last.warning")
			
			if (!is.null(last.warning)) {
				cat(.gettext("In addition: "))
				.WarningMessage(last.warning)
			}
			break
		}
		else {
			if (tmp$visible) 
				print(tmp$value)
			last.warning <- attr(tmp, "last.warning")
			if (!is.null(last.warning)) 
				.WarningMessage(last.warning)
		}
	}
	
	if (!inherits(tmp, "try-error")) {
		return(tmp$value)
	}
}


parseTxt <- function (text) {
	#this is svMisc::parseText
	text <- paste(text, collapse = "\n")
	code <- textConnection(text)
	expr <- try(parse(code), silent = TRUE)
	close(code)
	if (inherits(expr, "try-error")) {
		if (.compareRVersion("2.9.0") < 0) {
			toSearch <- paste("\n", length(strsplit(text, "\n")[[1]]) + 
							1, ":", sep = "")
		}
		else {
			toSearch <- paste(": ", length(strsplit(text, "\n")[[1]]) + 
							1, ":0:", sep = "")
		}
		if (length(grep(toSearch, expr)) == 1) 
			return(NA)
		else return(expr)
	}
	dp <- deparse(expr)
	if (regexpr("\\\\n\")$", dp) > 0 && regexpr("\n[\"'][ \t\r\n\v\f]*($|#.*$)", 
			text) < 0) 
		return(NA)
	if (regexpr("\n`)$", dp) > 0 && regexpr("\n`[ \t\r\n\v\f]*($|#.*$)", 
			text) < 0) 
		return(NA)
	return(expr)
}

.gettext <- function (msg, domain = "R") {
	#this is svMisc:::.gettext
	ngettext(1, msg, "", domain = domain)
}

.gettextf <- function (fmt, ..., domain = "R") {
	#this is svMisc:::.gettextf
	sprintf(ngettext(1, fmt, "", domain = domain), ...)
}

.compareRVersion <- function (version) {
	#this is svMisc::compareRVersion
	compareVersion(paste(R.version$major, R.version$minor, sep = "."), 
			version)
}

TempEnv <- function () {
	#this is svMisc::TempEnv
	pos <- match("TempEnv", search())
	if (is.na(pos)) {
		TempEnv <- list()
		attach(TempEnv, pos = length(search()) - 1)
		rm(TempEnv)
		pos <- match("TempEnv", search())
	}
	return(pos.to.env(pos))
}

.warningOverride <- function(..., call. = TRUE, immediate. = FALSE, 
		domain = NULL) {
	#used when warning() is called in stringExpr during evaluation by cap()
	args <- list(...)
	if (length(args) == 1 && inherits(args[[1]], "condition")) {
		base::warning(..., call. = call., immediate. = immediate., 
				domain = domain)
	}
	else {
		oldwarn <- getOption("warn")
		if (immediate. && oldwarn < 1) {
			options(warn = 1)
			on.exit(options(warn = oldwarn))
		}
		.Internal(warning(as.logical(call.), as.logical(immediate.), 
						.makeMessage(..., domain = domain)))
	}
}

.WarningMessage <- function(last.warning) {
	#.WarningMessage
	assign("last.warning", last.warning, envir = baseenv())
	n.warn <- length(last.warning)
	if (n.warn < 11) {
		print.warnings(warnings(" ", sep = ""))
	}
	else if (n.warn >= 50) {
		cat(.gettext("There were 50 or more warnings (use warnings() to see the first 50)\n"))
	}
	else {
		cat(.gettextf("There were %d warnings (use warnings() to see them)\n", 
						n.warn))
	}
	return(invisible(n.warn))
}

.evalVis <- function(Expr) {
	#.evalVis
	owarns <- getOption("warning.expression")
	options(warning.expression = expression())
	on.exit({
				nwarns <- getOption("warning.expression")
				if (!is.null(nwarns) && length(as.character(nwarns)) == 
						0) options(warning.expression = owarns)
			})
	
	res <- try(withCallingHandlers(withVisible(eval(Expr,.GlobalEnv, baseenv())), 
					warning = function(e) { .evalVisHandleWarning(e) }, 
					interrupt = function(i) cat(.gettext("<INTERRUPTED!>\n")), 
					error = function(e) { .evalVisHandleError(e) }, 
					message = function(e) { .evalVisHandleMessage(e) }
			), silent = TRUE)
	
	if (exists("warns", envir = TempEnv())) {
		warns <- get("warns", envir = TempEnv())
		last.warning <- lapply(warns, "[[", "call")
		names(last.warning) <- sapply(warns, "[[", "message")
		attr(res, "last.warning") <- last.warning
		rm("warns", envir = TempEnv())
	}
	return(res)
}

.evalVisHandleWarning <- function(e) {
	#.evalVisHandleWarning
	msg <- conditionMessage(e)
	call <- conditionCall(e)
	wl <- getOption("warning.length")
	if (is.null(wl)) 
		wl <- 1000
	if (nchar(msg) > wl) 
		msg <- paste(substr(msg, 1, wl), .gettext("[... truncated]"))
	Warn <- getOption("warn")
	if (!is.null(call) && identical(call[[1]], quote(eval.with.vis))) 
		e$call <- NULL
	if (Warn < 0) {
		return()
	}
	else if (Warn == 0) {
		if (exists("warns", envir = TempEnv())) {
			lwarn <- get("warns", envir = TempEnv())
		}
		else lwarn <- list()
		if (length(lwarn) >= 50) 
			return()
		assign("warns", append(lwarn, list(e)), envir = TempEnv())
		return()
	}
	else if (Warn > 1) {
		msg <- .gettextf("(converted from warning) %s", 
				msg)
		stop(simpleError(msg, call = call))
	}
	else {
		if (!is.null(call)) {
			dcall <- deparse(call)[1]
			prefix <- paste(.gettext("Warning in"), dcall, 
					": ")
			sm <- strsplit(msg, "\n")[[1]]
			if (nchar(dcall, type = "w") + nchar(sm[1], 
					type = "w") > 58) 
				prefix <- paste(prefix, "\n  ", sep = "")
		}
		else prefix <- .gettext("Warning : ")
		msg <- paste(prefix, msg, "\n", sep = "")
		cat(msg)
	}
}

.evalVisHandleError <- function(e) {
	#.evalVisHandleError
	call <- conditionCall(e)
	msg <- conditionMessage(e)
	if (!is.null(call) && identical(call[[1]], quote(eval.with.vis))) 
		call <- NULL
	if (!is.null(call)) {
		dcall <- deparse(call)[1]
		prefix <- paste(.gettext("Error in"), dcall, 
				": ")
		sm <- strsplit(msg, "\n")[[1]]
		if (nchar(dcall, type = "w") + nchar(sm[1], 
				type = "w") > 61) 
			prefix <- paste(prefix, "\n  ", sep = "")
	}
	else prefix <- .gettext("Error: ")
	msg <- paste(prefix, msg, "\n", sep = "")
	.Internal(seterrmessage(msg[1]))
	if (identical(getOption("show.error.messages"), 
			TRUE)) {
		cat(msg)
	}
}

.evalVisHandleMessage <- function(e) {
	#.evalVisHandleMessage
	signalCondition(e)
	conditionMessage(e)
}

.assignMatrix <- function(df) {
	#called from RFace.assignMatrix
	#to convert dataframe save from RFace.assignDataFrame
	#to a matrix
	dfm <- as.matrix(df[-1])
	rownames(dfm) <- df[[1]]
	dfm
}