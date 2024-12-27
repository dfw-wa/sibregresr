


pen_dlm<-function(dat){

options(na.action = "na.pass")
mod_mat<-model.matrix(y~x,data=dat)

n_coefs<-ncol(mod_mat)

n_years<-nrow(mod_mat)

data<-list(
  y=head(dat,-1)$y,
  mod_mat=mod_mat,
  n_coefs=n_coefs,
  n_years=n_years
)


#parameters


params<-list(

coef_inits=numeric(n_coefs)+1,
coef_inovations=matrix(.05,n_years-1,n_coefs),

mean_log_sd = numeric(n_coefs),

innov_log_sd = numeric(n_coefs),

resid_log_sd = 0
)


#likelihood
f <- function(parms) {
  "[<-" <- RTMB::ADoverload("[<-")
  RTMB::getAll(data, parms, warn=FALSE)


mean_sd<-exp(mean_log_sd)
innov_sd<-exp(innov_log_sd)
resid_sd<-exp(resid_log_sd)
#
nll<-0
#
coefs<-matrix(0,n_years,n_coefs)
coefs[1,]<-coef_inits
for(i in 2:n_years){
  coefs[i,]<-coefs[i-1,]+coef_inovations[i-1,]
}


for ( i in 1:n_coefs){
  nll<- nll - sum(RTMB::dnorm(coef_inovations[,i],0,innov_sd[i],log=TRUE)) # penalize year-to-year variations
}

coef_means<-(RTMB::apply(coefs,2,mean))
nll<-nll - sum(RTMB::dnorm(coef_means,0,mean_sd,log=TRUE)) #penalize mean of coefficients across years
nll<-nll - sum(RTMB::dexp(innov_sd,1,log=TRUE)) -sum (innov_log_sd)
nll<-nll - sum(RTMB::dexp(mean_sd,1,log=TRUE)) - sum(mean_log_sd)

pred<-RTMB::apply(coefs*mod_mat,1,sum)

nll<- nll-sum(RTMB::dnorm((y),(head(pred,-1)),resid_sd,log=TRUE))
RTMB::REPORT(pred)
RTMB::REPORT(nll)
nll
}


obj <- RTMB::MakeADFun(f, params,random=c("coef_inovations","coef_inits"),silent =TRUE)


#optimize
fit<-TMBhelper::fit_tmb(obj,newtonsteps =2,getJointPrecision  =FALSE,quiet =TRUE)

return(list(
  obj=obj,
  fit=fit
))
}

