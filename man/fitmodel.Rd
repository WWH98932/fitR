% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fitclasses.r
\name{fitmodel}
\alias{fitmodel}
\title{Constructor of fitmodel object}
\usage{
fitmodel(name = NULL, state.names = NULL, theta.names = NULL,
  simulate = NULL, rPointObs = NULL, dprior = NULL, dPointObs = NULL)
}
\arguments{
\item{name}{character. Name of the model (required).}

\item{state.names}{character vector. Names of the state variables i.e. \code{c("S","I","R")} (required).}

\item{theta.names}{character vector. Names of the parameters i.e. \code{c("R0","infectious.period")} (required).}

\item{simulate}{\R-function to simulate forward the model (required). This function takes 3 arguments:
\itemize{
\item \code{theta} named numeric vector. Values of the parameters. Names should match \code{theta.names}. 
\item \code{init.state} named numeric vector. Initial values of the state variables. Names should match \code{state.names}. 
\item \code{times} numeric vector. Time sequence for which the state of the model is wanted; the first value of times must be the initial time, i.e. the time of \code{init.state}.
}
and returns a \code{data.fame} containing the simulated trajectories that is the values of the state variables (1 per column) at each observation time (1 per row). The first column is \code{time}.}

\item{rPointObs}{\R-function that generates a (randomly sampled) observation point from a model point, using an observation model (optional). It thus acts as an inverse of \code{dPointObs} (see below). This function takes 2 arguments
\itemize{
\item \code{model.point} named numeric vector. State of the model at a given point in time.
\item \code{theta} named numeric vector. Values of the parameters. Names should match \code{theta.names}. 
}
and returns an observation point}

\item{dprior}{\R-function that evaluates the prior density of the parameters at a given \code{theta} (optional). The function should take 2 arguments:
\itemize{
    \item \code{theta} named numeric vector. Values of the parameters. Names should match \code{theta.names}. 
    \item \code{log} boolean. determines whether the logarithm of the prior density should be returned. 
}
and returns the (logged, if requested) value of the prior density distribution.}

\item{dPointObs}{\R-function that evaluates the likelihood of one data point given the state of the model at the same time point. This function takes 4 arguments:
\itemize{
\item \code{data.point} named numeric vector. Observation time and observed data point.
\item \code{model.point} named numeric vector containing the state of the model at the observation time point.
\item \code{theta} named numeric vector. Parameter values. Useful since parameters are usually needed to compute the likelihood (i.e. reporting rate).
\item \code{log} boolean. determines whether the logarithm of the likelihood should be returned. 
}
and returns the (log-)likelihood. (optional)}
}
\value{
a \code{fitmodel} object that is a \code{list} of 7 elements:
\itemize{
	\item \code{name} character, name of the model
	\item \code{state.names} vector, names of the state variables.
	\item \code{theta.names} vector, names of the parameters.
	\item \code{simulate} \R-function to simulate forward the model; usage: \code{simulate(theta,init.state,times)}.
	\item \code{rPointObs} \R-function to generate simulated observations; usage: \code{rPointObs(model.point, theta)}.
	\item \code{dprior} \R-function to evaluate the log-prior of the parameter values; usage: \code{dprior(theta)}.
	\item \code{dPointObs} \R-function to evaluate the log-likelihood of one data point; usage: \code{dPointObs(data.point, model.point, theta, log)}.
}
}
\description{
A \code{fitmodel} object is a \code{list} that stores some variables and functions that will be useful to simulate and fit your model during the course.
}
\examples{
## create a simple deterministic SIR model with constant population size

SIR_name <- "SIR with constant population size"
SIR_state.names <- c("S","I","R")
SIR_theta.names <- c("R0","D_inf")

SIR_simulateDeterministic <- function(theta,init.state,times) {

    SIR_ode <- function(time, state, parameters) {

        ## parameters
        beta <- parameters[["R0"]] / parameters[["D_inf"]]
        nu <- 1 / parameters[["D_inf"]]

        ## states
        S <- state[["S"]]
        I <- state[["I"]]
        R <- state[["R"]]

        N <- S + I + R

        dS <- -beta * S * I/N
        dI <- beta * S * I/N - nu * I
        dR <- nu * I

        return(list(c(dS, dI, dR)))
    }

    trajectory <- data.frame(ode(y = init.state,
                                 times = times,
                                 func = SIR_ode,
                                 parms = theta,
                                 method = "ode45"))

    return(trajectory)
}

## function to compute log-prior
SIR_prior <- function(theta, log = FALSE) {

    ## uniform prior on R0: U[1,100]
    log.prior.R0 <- dunif(theta[["R0"]], min = 1, max = 100, log = TRUE)
    ## uniform prior on infectious period: U[0,30]
    log.prior.D <- dunif(theta[["D_inf"]], min = 0, max = 30, log = TRUE)

    log.sum <- log.prior.R0 + log.prior.D

    return(ifelse(log, log.sum, exp(log.sum)))
}

## function to compute the likelihood of one data point
SIR_pointLike <- function(data.point, model.point, theta, log = FALSE){

    ## the prevalence is observed through a Poisson process
    return(dpois(x = data.point[["obs"]],
                 lambda = model.point[["I"]],
                 log = log))
}

## function to generate observation from a model simulation
SIR_genObsPoint <- function(model.point, theta){

    ## the prevalence is observed through a Poisson process
    obs.point <- rpois(n = 1, lambda = model.point[["I"]])

    return(c(obs = obs.point))
}

## create deterministic SIR fitmodel
SIR <- fitmodel(
    name = SIR_name,
    state.names = SIR_state.names,
    theta.names = SIR_theta.names,
    simulate = SIR_simulateDeterministic,
    dprior = SIR_prior,
    rPointObs = SIR_genObsPoint,
    dPointObs = SIR_pointLike)

## test
## theta <- c(R0 = 3, D_inf = 2)
## init.state <- c(S = 999, I = 1, R = 0)
## data(epi)
}
\seealso{
\code{\link{testFitmodel}}
}
