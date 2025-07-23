# apogee-control-sim
Simulations for RIT Launch's prototype apogee control system. 

A 2-DOF dynamic model simulates the rocket's dynamics and controller response.

# Model Architecture
Simulink *Subsystems* represent model components, which Simulink *Models*
assemble into test cases. Most model components are associated with a
`_params.m` that retrieve the model's parameters in a particular configuration
(a sensor can be "ideal" or a specific model number). 

```
data/   - raw flight data
        - generated data files (lookup tables)

sim/    - simulation models and subsystems
        - helper functions to interact with models

test/   - uses files in sim/ and data/ to produce test results
        - everything that produces a plot for a report goes here

```

In general, to run a simulation, 

1. Store the outputs of the required `_params.m` functions and initial conditions
(manually or from an OpenRocket output timetable) in variables.
2. Use `structs2inputs` to assign the fields of these structures to a
   Simulink.SimulationInput (which can be an array, if any structure is an array
   of random samples).
3. Use `sim` (possibly with Fast Restart) to obtain outputs from inputs.

Many of the calculations require large amounts of simulations. To keep things
reasonable, separate scripts run them and store the rseults in `.mat` files
under `data`.  To run default simulations---mainly `controller_monte` and
`controller_single`---it is necessary to first run `typical_variation` and
`generate_luts`.

# Installation instructions
## Required Products
1. Simulink
2. Aerospace Toolbox
3. Aerospace Blockset

## Download project and dependencies
For this repository and **each** Git dependency, perform the following actions **under a common folder**:

1. Create an empty folder **using the repository name: the word after RIT-Launch-Initiative**.
2. In the top-left of the MATLAB toolbar, use **New->Project->From Git** to clone the repository.
3. Repository path: URL of the repository, without `/tree/main` (if present).
4. Sandbox: Path to the folder you made.

At the end of this, your directory structure should look something like
```
<Common_folder_name>/
  apogee-control-sim/ 
    Apogeecontrolsim.prj
    [...]
  lmatlib/
    Lmatlib.prj
    [...]
```

Open this project's `.prj` file and ensure it loads without errors or broken references.

## Git dependencies
1. `https://github.com/RIT-Launch-Initiative/lmatlib`

# Acknowledgements
The first prototype's control scheme is heavily inspired by that used by
SAC-2024 Team 97 'ARES', in creating a LUT-based model-predictive controller
using offline simulations. Thank you to UoM ARES for making their work publicly
available. 

The current simulations use the OpenRocket model for Jake Halpern's L2 'CRUD' as
a base.
