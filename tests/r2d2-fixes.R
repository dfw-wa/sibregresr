library(sibregresr)

original_options <- options("na.action")
set.seed(42)
x <- rnorm(20)
dat <- data.frame(
  y = c(2 + 0.5 * x[1:19] + rnorm(19, sd = 0.3), NA),
  x = x
)

for (missing in c(FALSE, TRUE)) {
  input <- dat
  if (missing) input$x[5] <- NA_real_
  fit <- r2d2_dlm(input)
  stopifnot(
    is.finite(fit$obj$fn(fit$obj$par)),
    is.finite(fit$obj$report()$mu_forecast)
  )
}

models <- mod_funs(
  c("PenDlm", "r2d2DLM"),
  form = y ~ x + z,
  R2_b = NULL,
  regu = NULL
)
stopifnot(
  identical(formals(models$PenDlm)$form, y ~ x + z),
  identical(formals(models$r2d2DLM)$form, y ~ x + z),
  "regu" %in% names(formals(models$PenDlm)),
  is.null(formals(models$PenDlm)$regu),
  "R2_b" %in% names(formals(models$r2d2DLM)),
  is.null(formals(models$r2d2DLM)$R2_b),
  identical(formals(mod_funs("PenDlm")[[1]])$form, formals(pen_dlm)$form)
)
options(original_options)
