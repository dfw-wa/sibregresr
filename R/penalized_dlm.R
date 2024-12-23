

#data

x<-rnorm(n_years)

y<-.5+x*(-2+rnorm(n_years,0,.1))

dat<-dat |>  mutate(across(c(x,y),scale))

mod_mat<-model.matrix(y~x,data=dat)

data<-list(
  y=dat$y,
  mod_mat=mod_mat
)


#parameters
n_coefs<-2

n_years<-nrow(dat)


params<-list(
coef_inits=numeric(n_coefs)+.1,
coef_inovations=matrix(.05,n_years,n_coefs),

mean_log_sd = numeric(n_coefs)-1,

innov_log_sd = numeric(n_coefs)-1,

resid_log_sd = -1
)


#likelihood
f <- function(parms) {
  getAll(data, parms, warn=FALSE)

mean_sd<-exp(mean_log_sd)
innov_sd<-exp(innov_log_sd)
resid_sd<-exp(resid_log_sd)

nll<-0

coefs<-matrix(NA,n_years,n_coefs)
coefs[1,]<-coef_inits+coef_inovations[1,]
for(i in 2:n_years){
  coefs[i,]<-coefs[i-1,]+coef_inovations[i,]
}

for ( i in 1:n_coefs){
  nll<-nll - sum(dnorm(coef_inovations[,i],0,innov_sd[i],log=TRUE)) # penalize year-to-year variations
}

nll<-nll - sum(dnorm(colMeans(coefs),0,mean_sd,log=TRUE)) #penalize mean of coefficients
nll<-nll - sum(dexp(innov_sd,1,log=TRUE))
nll<-nll - sum(dexp(mean_sd,1,log=TRUE))

pred<-rowSums(coefs*mod_mat)

nll<- sum(dnorm(y,pred,resid_sd,log=TRUE))

nll
}
