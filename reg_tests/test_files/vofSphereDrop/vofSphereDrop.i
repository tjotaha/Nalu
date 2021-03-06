Simulation:
  name: NaluSim

linear_solvers:

  - name: solve_scalar
    type: tpetra
    method: gmres
    preconditioner: sgs 
    tolerance: 1e-5
    max_iterations: 50
    kspace: 50
    output_level: 0

  - name: solve_cont
    type: tpetra
    method: gmres 
    preconditioner: muelu
    tolerance: 1e-5
    max_iterations: 150
    kspace: 75
    output_level: 0
    muelu_xml_file_name: ../../xml/milestone.xml

realms:

  - name: realm_1
    mesh: ../../mesh/sphere_drop.g
    use_edges: no       
    automatic_decomposition_type: rcb

    time_step_control:
     target_courant: 1.0
     time_step_change_factor: 2.5
   
    equation_systems:
      name: theEqSys
      max_iterations: 2 
   
      solver_system_specification:
        velocity: solve_scalar
        volume_of_fluid: solve_scalar
        pressure: solve_cont

      systems:
        - LowMachEOM:
            name: myLowMach
            max_iterations: 1 
            convergence_tolerance: 1e-5
        - VolumeOfFluid:
            name: myV
            max_iterations: 1
            convergence_tolerance: 1.e-2
            activate_smoothing: yes
            fourier_number: 0.25
            compression_constant: 0.05

    initial_conditions:
      - constant: ic_1
        target_name: [ovr_mesh, bg_mesh]
        value:
          pressure: 0
          velocity: [0.0,0.0]

      - user_function: ic_2
        target_name: [ovr_mesh, bg_mesh]
        user_function_name:
          volume_of_fluid: RayleighTaylor
        user_function_parameters:
          volume_of_fluid: [0.001, 1.0, 2.0, 0.0001]

    material_properties:
      target_name: [ovr_mesh, bg_mesh]
      specifications:
        - name: density
          type: volume_of_fluid
          phase_one: 1.0
          phase_two: 1.5

        - name: viscosity
          type: volume_of_fluid
          phase_one: 0.001
          phase_two: 0.001

        - name: surface_tension
          type: constant
          value: 0.0

    boundary_conditions:

    - inflow_boundary_condition: top_bot
      target_name: surface_1
      inflow_user_data:
        velocity: [0,0,0]

    - open_boundary_condition: top_bot2
      target_name: surface_3
      open_user_data:
        velocity: [0,0,0]
        pressure: 0

    - wall_boundary_condition: sides1
      target_name: surface_4
      wall_user_data:
        velocity: [0,0,0]

    - wall_boundary_condition: sides2
      target_name: surface_2
      wall_user_data:
        velocity: [0,0,0]

    - overset_boundary_condition: sphere_edge
      overset_user_data:
        percent_overlap: 20.0
        percent_overlap_inner: 30.0
        background_block: bg_mesh
        overset_block: ovr_mesh
        overset_surface: surface_5
        background_cut_block: block_10
        background_cut_surface: surface_20

    - wall_boundary_condition: bc_sphere
      target_name: surface_6
      wall_user_data:
        user_function_name:
         velocity: mesh_motion
        user_function_string_parameters:
         velocity: [mmSphere_ss5]

    solution_options:
      name: myOptions


      mesh_motion:

        - name: mmBackground
          target_name: [bg_mesh]
          omega: 0.0

        - name: mmSphere_ss5
          target_name: [ovr_mesh]
          include_six_dof: yes
          body_omega: [0.0,0.0,0.0]
          body_mass: 0.981747
          body_velocity: [0,0,0]
          body_cc_disp: [0,3,0]
          principal_moments_inertia: [0.0,0.0,1.0]
          forcing_surface: [surface_6]
          applied_force: [0.0,-9.81,0.0]
          compute_centroid: yes

      use_consolidated_solver_algorithm: yes
      use_consolidated_face_elem_bc_algorithm: yes

      options:
        - element_source_terms:
            momentum: [lumped_momentum_time_derivative, advection_diffusion, buoyancy]
            continuity: [advection]
            volume_of_fluid: [lumped_mass, scv_advection, sucv_nso, sharpen]

        - user_constants:
            gravity: [0.0, -10.0]
            reference_density: 0.0

    output:
      output_data_base_name: sphere_drop.e
      output_frequency: 5 
      output_node_set: no 
      output_variables:
       - velocity
       - pressure
       - mesh_displacement
       - fringe_node
       - dpdx
       - dudx
       - intersected_element
       - mesh_velocity
       - density
       - volume_of_fluid
       - volume_of_fluid_smoothed
       - interface_normal
       - dvofdx

Time_Integrators:
  - StandardTimeIntegrator:
      name: ti_1
      start_time: 0
      termination_step_count: 20
      time_step: 0.005
      time_stepping_type: fixed
      time_step_count: 0
      second_order_accuracy: no

      realms:
        - realm_1
