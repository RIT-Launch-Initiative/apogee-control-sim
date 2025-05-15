function simin = setup_const_sim(simin)
    simin = simin.setVariable(control_mode = "const");
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");
    simin = simin.setModelParameter(SolverType = "Variable-step", SolverName = "ode45");
end
