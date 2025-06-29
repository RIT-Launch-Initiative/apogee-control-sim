# apogee-control-sim
Simulations for RIT Launch's prototype apogee control system. A 2-DOF dynamic
model simulates the rocket's dynamics and controller response.

# Structure
The core model is `sim_2dof.slx`. It defines a skeleton to populate with more
detailed models. Currently, the two major points of flexibility are the
controller and aerodynamic models.

```
data/   - raw flight data
        - generated data files (lookup tables)

sim/    - simulation models and subsystems
        - helper functions to interact with models

test/   - uses files in sim/ and data/ to produce test results
        - everything that produces a plot for a report goes here

```

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
