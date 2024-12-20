using MathOptInterface
######################
##### ROSENBROOK #####
######################
function rosenbrook1()
    model = Model()
    @variable(model, x)
    @variable(model, y)
    @NLobjective(model, Min, (2.0 - x)^2 + 100 * (y - x^2)^2)
    return model
end

function rosenbrook2()
    model = Model()
    @variable(model, x >= 0.0)
    @variable(model, y >= 0.0)
    @NLobjective(model, Min, (2.0 - x)^2 + 100 * (y - x^2)^2)
    @constraint(model, x + y >= 0.1)
    @NLconstraint(model, x * y + x >= 0.1)
    return model
end

function createHardCaseUsingSimpleBivariateConvexProblemJuMP()
    model = Model(CATrustRegionMethod.Optimizer)
    @variable(model, x)
    @variable(model, y)
    @NLobjective(model, Min, x^2 - 10 * x * y + y^2)
    return model
end

######################
####Utility Method####
######################
function attachSolverWithAttributesToJuMPModel(model::Model, options::Dict{String,Any})
    set_optimizer(model, CATrustRegionMethod.Optimizer)
    for (name, value) in options
        sname = string(name)
        set_optimizer_attribute(model, sname, value)
    end
end

function optimize_rosenbrook1_model_MOI_wrapper_with_default_arguments()
    default_β = 0.1
    default_θ = 0.1
    default_ω_1 = 8.0
    default_ω_2 = 16.0
    default_γ_1 = 1e-2
    default_γ_2 = 0.8
    default_r_1 = 0.0
    default_print_level = 0
    default_max_iterations = 100000
    default_gradient_termination_tolerance = 1e-5
    default_max_time = 5 * 60 * 60.0
    default_step_size_limit = 2.0e-16
    options = Dict{String,Any}(
        "algorithm_params!r_1" => default_r_1,
        "algorithm_params!β" => default_β,
        "algorithm_params!ω_2" => default_ω_2,
        "algorithm_params!print_level" => default_print_level,
        "termination_criteria!MAX_ITERATIONS" => default_max_iterations,
        "termination_criteria!gradient_termination_tolerance" =>
            default_gradient_termination_tolerance,
    )
    model = rosenbrook1()
    attachSolverWithAttributesToJuMPModel(model, options)

    #Test using JUMP
    optimize!(model)
    x = JuMP.value.(model[:x])
    y = JuMP.value.(model[:y])
    status = MOI.get(model, MOI.TerminationStatus())
    @test status == MOI.OPTIMAL
    @test MOI.get(model, MOI.RawStatusString()) == "Optimal"
    @test MOI.get(model, MOI.DualStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test abs(MOI.get(model, MOI.ObjectiveValue()) - 4.68876e-19) <= 1e-3

    @test MOI.get(model, MOI.Silent()) == true
    @test MOI.get(model, MOI.RawOptimizerAttribute("time_limit")) == default_max_time

    # Retrieve the solver instance
    optimizer = backend(model).optimizer.model

    nlp = MathOptNLPModel(model)
    termination_criteria = CATrustRegionMethod.TerminationCriteria()
    algorithm_params = CATrustRegionMethod.AlgorithmicParameters()

    x_k, status, iteration_stats, algorithm_counter, itr =
        CATrustRegionMethod.optimize(nlp, termination_criteria, algorithm_params, nlp.meta.x0, 0.0)

    @test algorithm_counter.total_function_evaluation == nlp.counters.neval_obj
    @test algorithm_counter.total_gradient_evaluation == nlp.counters.neval_grad
    @test algorithm_counter.total_hessian_evaluation == nlp.counters.neval_hess

    @test algorithm_counter.total_function_evaluation <= 35
    @test algorithm_counter.total_gradient_evaluation <= 25
    @test algorithm_counter.total_hessian_evaluation <= 25
    @test algorithm_counter.total_number_factorizations <= 110

    @test x_k == [x, y]
    @test itr == optimizer.inner.itr
    @test x_k == optimizer.inner.x
    @test status == CATrustRegionMethod.TerminationStatusCode.OPTIMAL
    @test iteration_stats == optimizer.inner.iteration_stats

    @test algorithm_counter.total_function_evaluation ==
          optimizer.inner.algorithm_counter.total_function_evaluation
    @test algorithm_counter.total_gradient_evaluation ==
          optimizer.inner.algorithm_counter.total_gradient_evaluation
    @test algorithm_counter.total_hessian_evaluation ==
          optimizer.inner.algorithm_counter.total_hessian_evaluation
    @test algorithm_counter.total_number_factorizations ==
          optimizer.inner.algorithm_counter.total_number_factorizations
    @test algorithm_counter.total_number_factorizations_findinterval ==
          optimizer.inner.algorithm_counter.total_number_factorizations_findinterval
    @test algorithm_counter.total_number_factorizations_bisection ==
          optimizer.inner.algorithm_counter.total_number_factorizations_bisection
    @test algorithm_counter.total_number_factorizations_compute_search_direction ==
          optimizer.inner.algorithm_counter.total_number_factorizations_compute_search_direction
    @test algorithm_counter.total_number_factorizations_inverse_power_iteration ==
          optimizer.inner.algorithm_counter.total_number_factorizations_inverse_power_iteration

    @test optimizer.inner.algorithm_params.β == default_β
    @test optimizer.inner.algorithm_params.θ == default_θ
    @test optimizer.inner.algorithm_params.ω_1 == default_ω_1
    @test optimizer.inner.algorithm_params.ω_2 == default_ω_2
    @test optimizer.inner.algorithm_params.γ_1 == default_γ_1
    @test optimizer.inner.algorithm_params.γ_2 == default_γ_2
    @test optimizer.inner.algorithm_params.r_1 == default_r_1
    @test optimizer.inner.algorithm_params.print_level == default_print_level
    @test optimizer.inner.termination_criteria.MAX_ITERATIONS == default_max_iterations
    @test optimizer.inner.termination_criteria.gradient_termination_tolerance ==
          default_gradient_termination_tolerance
    @test optimizer.inner.termination_criteria.MAX_TIME == default_max_time
    @test optimizer.inner.termination_criteria.STEP_SIZE_LIMIT == default_step_size_limit
end

function optimize_rosenbrook1_model_MOI_wrapper_with_user_specified_arguments()
    β = 0.2
    ω_2 = 8.0
    r_1 = 100.0
    print_level = -1
    MAX_ITERATIONS = 10
    gradient_termination_tolerance = 1e-3
    options = Dict{String,Any}(
        "algorithm_params!r_1" => r_1,
        "algorithm_params!β" => β,
        "algorithm_params!ω_2" => ω_2,
        "algorithm_params!print_level" => print_level,
        "termination_criteria!MAX_ITERATIONS" => MAX_ITERATIONS,
        "termination_criteria!gradient_termination_tolerance" =>
            gradient_termination_tolerance,
    )
    model = rosenbrook1()
    attachSolverWithAttributesToJuMPModel(model, options)

    #Test using JUMP (UserLimit due to MAX_ITERATIONS = 10)
    optimize!(model)
    x = JuMP.value.(model[:x])
    y = JuMP.value.(model[:y])
    status = MOI.get(model, MOI.TerminationStatus())
    @test status == MOI.OTHER_LIMIT

    # Retrieve the solver instance
    optimizer = backend(model).optimizer.model

    nlp = MathOptNLPModel(model)
    termination_criteria = CATrustRegionMethod.TerminationCriteria()
    algorithm_params = CATrustRegionMethod.AlgorithmicParameters()

    algorithm_params.β = β
    algorithm_params.ω_2 = ω_2
    algorithm_params.r_1 = r_1
    algorithm_params.print_level = print_level
    termination_criteria.MAX_ITERATIONS = MAX_ITERATIONS
    termination_criteria.gradient_termination_tolerance = gradient_termination_tolerance
    x_k, status, iteration_stats, algorithm_counter, itr =
        CATrustRegionMethod.optimize(nlp, termination_criteria, algorithm_params, nlp.meta.x0, 0.0)

    @test algorithm_counter.total_function_evaluation == nlp.counters.neval_obj
    @test algorithm_counter.total_gradient_evaluation == nlp.counters.neval_grad
    @test algorithm_counter.total_hessian_evaluation == nlp.counters.neval_hess

    @test algorithm_counter.total_function_evaluation <= 15
    @test algorithm_counter.total_gradient_evaluation <= 10
    @test algorithm_counter.total_hessian_evaluation <= 10
    @test algorithm_counter.total_number_factorizations <= 45

    @test x_k == [x, y]
    @test itr == optimizer.inner.itr
    @test x_k == optimizer.inner.x
    @test status == CATrustRegionMethod.TerminationStatusCode.ITERATION_LIMIT
    @test iteration_stats == optimizer.inner.iteration_stats

    @test algorithm_counter.total_function_evaluation ==
          optimizer.inner.algorithm_counter.total_function_evaluation
    @test algorithm_counter.total_gradient_evaluation ==
          optimizer.inner.algorithm_counter.total_gradient_evaluation
    @test algorithm_counter.total_hessian_evaluation ==
          optimizer.inner.algorithm_counter.total_hessian_evaluation
    @test algorithm_counter.total_number_factorizations ==
          optimizer.inner.algorithm_counter.total_number_factorizations
    @test algorithm_counter.total_number_factorizations_findinterval ==
          optimizer.inner.algorithm_counter.total_number_factorizations_findinterval
    @test algorithm_counter.total_number_factorizations_bisection ==
          optimizer.inner.algorithm_counter.total_number_factorizations_bisection
    @test algorithm_counter.total_number_factorizations_compute_search_direction ==
          optimizer.inner.algorithm_counter.total_number_factorizations_compute_search_direction
    @test algorithm_counter.total_number_factorizations_inverse_power_iteration ==
          optimizer.inner.algorithm_counter.total_number_factorizations_inverse_power_iteration

    @test optimizer.inner.algorithm_params.β == β
    @test optimizer.inner.algorithm_params.ω_2 == ω_2
    @test optimizer.inner.algorithm_params.r_1 == r_1
    @test optimizer.inner.algorithm_params.print_level == print_level
    @test optimizer.inner.termination_criteria.MAX_ITERATIONS == MAX_ITERATIONS
    @test optimizer.inner.termination_criteria.gradient_termination_tolerance ==
          gradient_termination_tolerance
end

function optimize_model_with_constraints_failure_expected()
    model = rosenbrook2()
    set_optimizer(model, CATrustRegionMethod.Optimizer)
    try
        optimize!(model)
    catch e
        @test e == MOI.UnsupportedConstraint{
            MathOptInterface.VariableIndex,
            MathOptInterface.GreaterThan{Float64},
        }(
            "",
        )
    end
end

function optimizeHardCaseUsingSimpleBivariateConvexProblem()
    model = createHardCaseUsingSimpleBivariateConvexProblemJuMP()

    #Test using JUMP
    optimize!(model)
    x = JuMP.value.(model[:x])
    y = JuMP.value.(model[:y])
    status = MOI.get(model, MOI.TerminationStatus())
    @test status == MOI.OPTIMAL
    # Retrieve the solver instance
    optimizer = backend(model).optimizer.model

    nlp = MathOptNLPModel(model)
    termination_criteria = CATrustRegionMethod.TerminationCriteria()
    algorithm_params = CATrustRegionMethod.AlgorithmicParameters()

    x_k, status, iteration_stats, algorithm_counter, itr =
        CATrustRegionMethod.optimize(nlp, termination_criteria, algorithm_params, nlp.meta.x0, 0.0)

    @test algorithm_counter.total_function_evaluation == nlp.counters.neval_obj
    @test algorithm_counter.total_gradient_evaluation == nlp.counters.neval_grad
    @test algorithm_counter.total_hessian_evaluation == nlp.counters.neval_hess

    computation_stats = Dict(
        "total_number_factorizations_compute_search_direction" => 0,
        "total_hessian_evaluation" => 1,
        "total_number_factorizations_findinterval" => 0,
        "total_gradient_evaluation" => 1,
        "total_number_factorizations" => 0,
        "total_number_factorizations_bisection" => 0,
        "total_function_evaluation" => 1,
        "total_number_factorizations_inverse_power_iteration" => 0,
    )

    @test algorithm_counter.total_function_evaluation ==
          computation_stats["total_function_evaluation"]
    @test algorithm_counter.total_gradient_evaluation ==
          computation_stats["total_gradient_evaluation"]
    @test algorithm_counter.total_hessian_evaluation ==
          computation_stats["total_hessian_evaluation"]
    @test algorithm_counter.total_number_factorizations ==
          computation_stats["total_number_factorizations"]
    @test algorithm_counter.total_number_factorizations_findinterval ==
          computation_stats["total_number_factorizations_findinterval"]
    @test algorithm_counter.total_number_factorizations_bisection ==
          computation_stats["total_number_factorizations_bisection"]
    @test algorithm_counter.total_number_factorizations_compute_search_direction ==
          computation_stats["total_number_factorizations_compute_search_direction"]
    @test algorithm_counter.total_number_factorizations_inverse_power_iteration ==
          computation_stats["total_number_factorizations_inverse_power_iteration"]


    @test x_k == [x, y]
    @test itr == optimizer.inner.itr
    @test x_k == optimizer.inner.x
    @test status == CATrustRegionMethod.TerminationStatusCode.OPTIMAL
    @test iteration_stats == optimizer.inner.iteration_stats

    @test algorithm_counter.total_function_evaluation ==
          optimizer.inner.algorithm_counter.total_function_evaluation
    @test algorithm_counter.total_gradient_evaluation ==
          optimizer.inner.algorithm_counter.total_gradient_evaluation
    @test algorithm_counter.total_hessian_evaluation ==
          optimizer.inner.algorithm_counter.total_hessian_evaluation
    @test algorithm_counter.total_number_factorizations ==
          optimizer.inner.algorithm_counter.total_number_factorizations
    @test algorithm_counter.total_number_factorizations_findinterval ==
          optimizer.inner.algorithm_counter.total_number_factorizations_findinterval
    @test algorithm_counter.total_number_factorizations_bisection ==
          optimizer.inner.algorithm_counter.total_number_factorizations_bisection
    @test algorithm_counter.total_number_factorizations_compute_search_direction ==
          optimizer.inner.algorithm_counter.total_number_factorizations_compute_search_direction
    @test algorithm_counter.total_number_factorizations_inverse_power_iteration ==
          optimizer.inner.algorithm_counter.total_number_factorizations_inverse_power_iteration
end

function optimize_rosenbrook1_model_MOI_wrapper_with_user_specified_attributes()
    # time_limit and output_flag
    β = 0.2
    ω_2 = 8.0
    r_1 = 100.0
    print_level = -1
    MAX_ITERATIONS = 100
    MAX_TIME = 5 * 60.0
    gradient_termination_tolerance = 1e-3
    options = Dict{String,Any}(
        "algorithm_params!r_1" => r_1,
        "algorithm_params!β" => β,
        "algorithm_params!ω_2" => ω_2,
        "algorithm_params!print_level" => print_level,
        "termination_criteria!MAX_ITERATIONS" => MAX_ITERATIONS,
        "termination_criteria!MAX_TIME" => MAX_TIME,
        "termination_criteria!gradient_termination_tolerance" =>
            gradient_termination_tolerance,
    )
    model = rosenbrook1()
    attachSolverWithAttributesToJuMPModel(model, options)

    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MOI.TimeLimitSec(), MAX_TIME)
    @test MOI.get(model, MOI.Silent()) == true
    @test MOI.get(model, MOI.TimeLimitSec()) == MAX_TIME
    @test MOI.get(model, MOI.RawOptimizerAttribute("time_limit")) == MAX_TIME

    optimize!(model)

    @test MOI.get(model, MOI.Silent()) == true
    @test MOI.get(model, MOI.TimeLimitSec()) == MAX_TIME
    @test MOI.get(model, MOI.RawOptimizerAttribute("time_limit")) == MAX_TIME

    MOI.set(model, MOI.Silent(), false)
    @test MOI.get(model, MOI.Silent()) == false
    MOI.set(model, MOI.RawOptimizerAttribute("time_limit"), 2 * MAX_TIME)
    @test MOI.get(model, MOI.TimeLimitSec()) == 2 * MAX_TIME
    @test MOI.get(model, MOI.RawOptimizerAttribute("time_limit")) == 2 * MAX_TIME
    MOI.set(model, MOI.RawOptimizerAttribute("algorithm_params!r_1"), 2 * r_1)

    # Retrieve the solver instance
    optimizer = backend(model).optimizer.model
    @test optimizer.inner.termination_criteria.MAX_TIME == MAX_TIME
    @test optimizer.inner.algorithm_params.print_level == -1
    @test optimizer.inner.algorithm_params.r_1 == r_1

    # call optimize again (the previous modifications should be reflected in the optimizer)
    optimize!(model)
    # Retrieve the solver instance
    optimizer = backend(model).optimizer.model
    @test optimizer.inner.termination_criteria.MAX_TIME == 2 * MAX_TIME
    @test optimizer.inner.algorithm_params.print_level == 0
    @test optimizer.inner.algorithm_params.r_1 == 2 * r_1
end

function optimize_models_MOI_wrapper()
    optimize_rosenbrook1_model_MOI_wrapper_with_default_arguments()
    optimize_rosenbrook1_model_MOI_wrapper_with_user_specified_arguments()
    optimize_model_with_constraints_failure_expected()
    optimizeHardCaseUsingSimpleBivariateConvexProblem()
    optimize_rosenbrook1_model_MOI_wrapper_with_user_specified_attributes()
end

@testset "optimization_using_MOI_wrapper" begin
    optimize_models_MOI_wrapper()
end
