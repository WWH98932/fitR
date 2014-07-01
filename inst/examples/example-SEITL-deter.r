
SEITL_deter_name <- "deterministic SEITL model with daily incidence and constant population size"
# note the new state Inc for the daily incidence
SEITL_state.names <- c("S","E","I","T","L","Inc")
SEITL_theta.names <- c("R0", "D.lat", "D.inf", "alpha", "D.imm", "rho")


# Solves the system of ordinary differential equations for the SEITL model.
SEITL_simulateDeterministic <- function(theta,state.init,times) {

	SEITL_ode <- function(time, state, theta) {

		# param
		beta <- theta[["R0"]]/theta[["D.inf"]]
		epsilon <- 1/theta[["D.lat"]]
		nu <- 1/theta[["D.inf"]]
		alpha <- theta[["alpha"]]
		tau <- 1/theta[["D.imm"]]

		# states
		S <- state[["S"]]
		E <- state[["E"]]
		I <- state[["I"]]
		T <- state[["T"]]
		L <- state[["L"]]
		Inc <- state[["Inc"]]

		N <- S + E +I + T + L

		dS <- -beta*S*I/N + (1-alpha)*tau*T
		dE <- beta*S*I/N - epsilon*E
		dI <- epsilon*E - nu*I
		dT <- nu*I - tau*T
		dL <- alpha*tau*T
		dInc <- epsilon*E

		return(list(c(dS,dE,dI,dT,dL,dInc)))
	}


	# put incidence at 0 in state.init
	state.init["Inc"] <- 0

	traj <- as.data.frame(ode(state.init, times, SEITL_ode, theta, method = "ode45"))

	# compute incidence of each time interval
	traj <- mutate(traj,Inc=c(0,diff(Inc)))

	return(traj)

}

# Simulate realisation of the stochastic version of the SEITL model.
SEITL_simulateStochastic <- function(theta,state.init,times) {

	
	SEITL_transitions <- list(
		c(S=-1,E=1),# infection
		c(E=-1,I=1,Inc=1),# infectiousness + incidence
		c(I=-1,T=1),# recovery + short term protection
		c(T=-1,L=1),# efficient long term protection
		c(T=-1,S=1)# deficient long term protection
		)

	SEITL_rateFunc <- function(state,theta,t) {

		# param
		beta <- theta[["R0"]]/theta[["D.inf"]]
		epsilon <- 1/theta[["D.lat"]]
		nu <- 1/theta[["D.inf"]]
		alpha <- theta[["alpha"]]
		tau <- 1/theta[["D.imm"]]

		# states
		S <- state[["S"]]
		E <- state[["E"]]
		I <- state[["I"]]
		T <- state[["T"]]
		L <- state[["L"]]
		Inc <- state[["Inc"]]

		N <- S + E +I + T + L

		return(c(
			beta*S*I/N, # infection
			epsilon*E, # infectiousness + incidence
			nu*I, # recovery + short term protection
			alpha*tau*T, # efficient long term protection
			(1-alpha)*tau*T # deficient long term protection
			)
		)
	}

	# put incidence at 0 in state.init
	state.init["Inc"] <- 0

	traj <- simulateModelStochastic(theta,state.init,times,SEITL_transitions,SEITL_rateFunc) 
	
	# compute incidence of each time interval
	traj <- mutate(traj,Inc=c(0,diff(Inc)))

	return(traj)

}

# Generate an observed incidence under a Poisson observation process.  
SEITL_genObsPoint <- function(model.point, theta){

	obs.point <- rpois(n=1, lambda=theta[["rho"]]*model.point[["Inc"]])

	return(obs.point)
}

# Evaluate the log of the prior density distribution of the parameter values.
SEITL_logPrior <- function(theta) {

	log.prior.R0 <- dunif(theta["R0"], min = 1, max = 100, log = TRUE)
	log.prior.latent.period <- dunif(theta["D.lat"], min = 0, max = 30, log = TRUE)
	log.prior.infectious.period <- dunif(theta["D.inf"], min = 0, max = 30, log = TRUE)
	log.prior.temporary.immune.period <- dunif(theta["D.imm"], min = 0, max = 50, log = TRUE)
	log.prior.probability.long.term.immunity <- dunif(theta["alpha"], min = 0, max = 1, log = TRUE)
	log.prior.reporting.rate <- dunif(theta["rho"], min = 0, max = 2, log = TRUE)
	
	return(log.prior.R0 + log.prior.latent.period + log.prior.infectious.period + log.prior.temporary.immune.period + log.prior.probability.long.term.immunity + log.prior.reporting.rate)

}


# Computes the log-likelihood of a data point given the state of the model and under a poisson observation process.
SEITL_pointLogLike <- function(data.point, model.point, theta){

	return(dpois(x=data.point[["obs"]],lambda=theta[["rho"]]*model.point[["Inc"]],log=TRUE))

}


# create fitmodel
SEITL_deter <- fitmodel(
	name=SEITL_deter_name,
	state.names=SEITL_state.names,
	theta.names=SEITL_theta.names,
	simulate=SEITL_simulateDeterministic,
	genObsPoint=SEITL_genObsPoint,
	logPrior=SEITL_logPrior,
	pointLogLike=SEITL_pointLogLike)

## test it

# theta <- c("R0"=10, "D.lat"=2 , "D.inf"=3, "alpha"=0.5, "D.imm"=15, "rho"=0.7)
# state.init <- c("S"=280,"E"=0,"I"=2,"T"=0,"L"=4,"Inc"=0)
# data(FluTdC1971)
# testFitmodel(fitmodel=SEITL, theta=theta, state.init=state.init, data= FluTdC1971, verbose=TRUE)


