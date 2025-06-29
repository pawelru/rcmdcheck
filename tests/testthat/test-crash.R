if (!isTRUE(as.logical(Sys.getenv("RCMDCHECK_EXTRA_TESTS")))) return()

test_that("check process crashes", {
  skip_on_cran()
  if (!ps::ps_is_supported()) skip("Needs working ps")

  chkdir = tempfile()
  on.exit(unlink(chkdir, recursive = TRUE), add = TRUE)
  pkgbuild::without_cache(pkgbuild::local_build_tools())
  targz <- build_package(
    test_path("bad4"),
    tempfile(),
    character(),
    .libPaths(),
    quiet = TRUE
  )

  pidfile <- tempfile(fileext = ".pid")
  dbgfile <- tempfile(fileext = ".R")
  on.exit(unlink(c(pidfile, dbgfile)), add = TRUE)
  code <- sprintf(
    "if (! file.exists('%s')) cat(Sys.getpid(), '\\n', file = '%s')\n",
    encodeString(pidfile),
    encodeString(pidfile)
  )
  cat(code, file = dbgfile)

  # Run rcmdcheck() in a subprocess, it will report back in the tmp_out file
  subchk <- function(path, dbgfile) {
    rcmdcheck::rcmdcheck(path, env = c(R_TESTS = dbgfile))
  }
  proc <- callr::r_bg(subchk, list(path = targz, dbgfile = dbgfile))

  # Wait until the check is running
  limit <- Sys.time() + as.difftime(10, units = "secs")
  while (!file.exists(pidfile) && Sys.time() < limit) Sys.sleep(0.1)
  expect_true(Sys.time() < limit)
  if (!file.exists(pidfile)) return()

  # Get a pid for the check process
  get_pid <- function() {
    tryCatch(as.integer(readLines(pidfile)), error = function(e) NULL)
  }
  limit <- Sys.time() + as.difftime(1, units = "secs")
  while (!is.integer(pid <- get_pid()) && Sys.time() < limit) Sys.sleep(0.1)
  expect_true(Sys.time() < limit)
  if (is.null(pid)) return()

  # Kill the check process
  Sys.sleep(1)
  ps::ps_kill(ps::ps_handle(pid))

  # Wait for the rcmdcheck() process to quit
  limit <- Sys.time() + as.difftime(10, units = "secs")
  while (proc$is_alive() && Sys.time() < limit) Sys.sleep(0.1)
  expect_true(Sys.time() < limit)
  if (proc$is_alive()) {
    proc$kill()
    return()
  }

  # Result of rcmdcheck()
  expect_snapshot(error = TRUE, proc$get_result())
})
