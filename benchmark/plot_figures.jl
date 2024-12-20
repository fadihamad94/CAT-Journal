using CSV, Plots, DataFrames
using Printf
const CAT_I_FACTORIZATION = "CAT_I_FACTORIZATION"
const CAT_II_FACTORIZATION = "CAT_II_FACTORIZATION"
const CAT_II_THETA_ZERO_FACTORIZATION = "CAT_II_THETA_ZERO_FACTORIZATION"
const ARC_FACTORIZATION = "ARC_FACTORIZATION"
const TRU_FACTORIZATION = "TRU_FACTORIZATION"

const CAT_I_FACTORIZATION_COLOR = :blue
const CAT_II_FACTORIZATION_COLOR = :black
const CAT_II_THETA_ZERO_FACTORIZATION_COLOR = :red
const ARC_FACTORIZATION_COLOR = :orange
const TRU_FACTORIZATION_COLOR = :purple

ITR_LIMIT = 100000
TIME_LIMIT = 18000

TOTAL_ITERATIONS = [Int(5 * i) for i = 1:(ITR_LIMIT/5)]
TOTAL_TIME = exp10.(collect(range(-1, log(10, TIME_LIMIT + 0.01), length = 3600)))

TOTAL_OBJ_VECTOR = exp10.(collect(range(-6, 6, length = 1000000)))
function readFile(fileName::String)
    df = DataFrame(CSV.File(fileName))
    return df
end

function filterRows(total_iterations_max::Int64, iterations_vector::Vector{Int64})
    return filter!(x -> x < total_iterations_max, iterations_vector)
end
function filterRows(total_iterations_max::Int64, iterations_vector::Vector{Float64})
    return filter!(x -> x < total_iterations_max, iterations_vector)
end
function filterRows(total_iterations_max::Float64, iterations_vector::Vector{Float64})
    return filter!(x -> x < total_iterations_max, iterations_vector)
end
function filterRowsObj(relative_obj_error::Float64, obj_values_vector::Vector{Float64})
    return filter!(x -> x <= relative_obj_error, obj_values_vector)
end

function computeFraction(df::DataFrame, TOTAL::Vector{Int64}, criteria::String)
    total_number_problems = size(df)[1]

    if criteria == "Functions"
        results_fraction = DataFrame(
            Functions = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Functions = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Gradients"
        results_fraction = DataFrame(
            Gradients = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Gradients = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Hessian"
        results_fraction = DataFrame(
            Hessian = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Hessian = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Factorization"
        results_fraction = DataFrame(
            Factorization = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Factorization = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Time"
        results_fraction = DataFrame(
            Time = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Time = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    else #Obj
        results_fraction = DataFrame(
            Obj = Float64[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Obj = Float64[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    end

    if criteria == "Obj"
        df_temp = select(df, Not(:PROBLEM_NAME))
        df_temp = select(df_temp, Not(:CAT_II_THETA_ZERO_FACTORIZATION))
        # Calculate the minimum obj_value per row
        min_obj_val = [minimum(row) for row in eachrow(df_temp)]

        # Update each numeric column to be the old column value minus the minimum value per row
        for col in names(df_temp)
            df[!, col] .= df[!, col] .- min_obj_val
        end

        for total in TOTAL
            total_problems_CAT_I_FACTORIZATION =
                length(filterRowsObj(total, df[:, CAT_I_FACTORIZATION]))
            total_problems_CAT_II_FACTORIZATION =
                length(filterRowsObj(total, df[:, CAT_II_FACTORIZATION]))
            total_problems_CAT_II_THETA_ZERO_FACTORIZATION = 0
            total_problems_ARC_FACTORIZATION =
                length(filterRowsObj(total, df[:, ARC_FACTORIZATION]))
            total_problems_TRU_FACTORIZATION =
                length(filterRowsObj(total, df[:, TRU_FACTORIZATION]))
            push!(
                results_fraction,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION / total_number_problems,
                    total_problems_ARC_FACTORIZATION / total_number_problems,
                    total_problems_TRU_FACTORIZATION / total_number_problems,
                ),
            )
            push!(
                results_total,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION,
                    total_problems_CAT_II_FACTORIZATION,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION,
                    total_problems_ARC_FACTORIZATION,
                    total_problems_TRU_FACTORIZATION,
                ),
            )
        end
    else
        for total in TOTAL
            total_problems_CAT_I_FACTORIZATION =
                length(filterRows(total, df[:, CAT_I_FACTORIZATION]))
            total_problems_CAT_II_FACTORIZATION =
                length(filterRows(total, df[:, CAT_II_FACTORIZATION]))
            total_problems_CAT_II_THETA_ZERO_FACTORIZATION =
                length(filterRows(total, df[:, CAT_II_THETA_ZERO_FACTORIZATION]))
            total_problems_ARC_FACTORIZATION =
                length(filterRows(total, df[:, ARC_FACTORIZATION]))
            total_problems_TRU_FACTORIZATION =
                length(filterRows(total, df[:, TRU_FACTORIZATION]))
            push!(
                results_fraction,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION / total_number_problems,
                    total_problems_ARC_FACTORIZATION / total_number_problems,
                    total_problems_TRU_FACTORIZATION / total_number_problems,
                ),
            )
            push!(
                results_total,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION,
                    total_problems_CAT_II_FACTORIZATION,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION,
                    total_problems_ARC_FACTORIZATION,
                    total_problems_TRU_FACTORIZATION,
                ),
            )
        end
    end

    return results_fraction
end

function computeFraction_CAT(df::DataFrame, TOTAL::Vector{Int64}, criteria::String)
    total_number_problems = size(df)[1]

    if criteria == "Functions"
        results_fraction = DataFrame(
            Functions = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Functions = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
    elseif criteria == "Gradients"
        results_fraction = DataFrame(
            Gradients = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Gradients = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
    elseif criteria == "Hessian"
        results_fraction = DataFrame(
            Hessian = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Hessian = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
    elseif criteria == "Factorization"
        results_fraction = DataFrame(
            Factorization = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Factorization = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
    elseif criteria == "Time"
        results_fraction = DataFrame(
            Time = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Time = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
    else #Obj
        results_fraction = DataFrame(
            Obj = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Obj = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
        )
    end

    for total in TOTAL
        total_problems_CAT_II_FACTORIZATION =
            length(filterRows(total, df[:, CAT_II_FACTORIZATION]))
        total_problems_CAT_II_THETA_ZERO_FACTORIZATION =
            length(filterRows(total, df[:, CAT_II_THETA_ZERO_FACTORIZATION]))

        push!(
            results_fraction,
            (
                total,
                total_problems_CAT_II_FACTORIZATION / total_number_problems,
                total_problems_CAT_II_THETA_ZERO_FACTORIZATION / total_number_problems,
            ),
        )
        push!(
            results_total,
            (
                total,
                total_problems_CAT_II_FACTORIZATION,
                total_problems_CAT_II_THETA_ZERO_FACTORIZATION,
            ),
        )
    end

    return results_fraction
end

function computeFraction(df::DataFrame, TOTAL::Vector{Float64}, criteria::String)
    total_number_problems = size(df)[1]

    if criteria == "Functions"
        results_fraction = DataFrame(
            Functions = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Functions = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Gradients"
        results_fraction = DataFrame(
            Gradients = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Gradients = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Hessian"
        results_fraction = DataFrame(
            Hessian = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Hessian = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Factorization"
        results_fraction = DataFrame(
            Factorization = Int[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Factorization = Int[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    elseif criteria == "Time"
        results_fraction = DataFrame(
            Time = Float64[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Time = Float64[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    else #Obj
        results_fraction = DataFrame(
            Obj = Float64[],
            CAT_I_FACTORIZATION = Float64[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Float64[],
            ARC_FACTORIZATION = Float64[],
            TRU_FACTORIZATION = Float64[],
        )
        results_total = DataFrame(
            Obj = Float64[],
            CAT_I_FACTORIZATION = Int[],
            CAT_II_FACTORIZATION = Float64[],
            CAT_II_THETA_ZERO_FACTORIZATION = Int[],
            ARC_FACTORIZATION = Int[],
            TRU_FACTORIZATION = Int[],
        )
    end

    if criteria == "Obj"
        df_temp = select(df, Not(:PROBLEM_NAME))
        df_temp = select(df_temp, Not(:CAT_II_THETA_ZERO_FACTORIZATION))
        # Calculate the minimum obj_value per row
        min_obj_val = [minimum(row) for row in eachrow(df_temp)]

        # Update each numeric column to be the old column value minus the minimum value per row
        for col in names(df_temp)
            df[!, col] .= df[!, col] .- min_obj_val
        end

        for total in TOTAL
            total_problems_CAT_I_FACTORIZATION =
                length(filterRowsObj(total, df[:, CAT_I_FACTORIZATION]))
            total_problems_CAT_II_FACTORIZATION =
                length(filterRowsObj(total, df[:, CAT_II_FACTORIZATION]))
            total_problems_CAT_II_THETA_ZERO_FACTORIZATION = 0
            total_problems_ARC_FACTORIZATION =
                length(filterRowsObj(total, df[:, ARC_FACTORIZATION]))
            total_problems_TRU_FACTORIZATION =
                length(filterRowsObj(total, df[:, TRU_FACTORIZATION]))
            push!(
                results_fraction,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION / total_number_problems,
                    total_problems_ARC_FACTORIZATION / total_number_problems,
                    total_problems_TRU_FACTORIZATION / total_number_problems,
                ),
            )
            push!(
                results_total,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION,
                    total_problems_CAT_II_FACTORIZATION,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION,
                    total_problems_ARC_FACTORIZATION,
                    total_problems_TRU_FACTORIZATION,
                ),
            )
        end
    else

        for total in TOTAL
            total_problems_CAT_I_FACTORIZATION =
                length(filterRows(total, df[:, CAT_I_FACTORIZATION]))
            total_problems_CAT_II_FACTORIZATION =
                length(filterRows(total, df[:, CAT_II_FACTORIZATION]))
            total_problems_CAT_II_THETA_ZERO_FACTORIZATION =
                length(filterRows(total, df[:, CAT_II_THETA_ZERO_FACTORIZATION]))
            total_problems_ARC_FACTORIZATION =
                length(filterRows(total, df[:, ARC_FACTORIZATION]))
            total_problems_TRU_FACTORIZATION =
                length(filterRows(total, df[:, TRU_FACTORIZATION]))
            push!(
                results_fraction,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_FACTORIZATION / total_number_problems,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION / total_number_problems,
                    total_problems_ARC_FACTORIZATION / total_number_problems,
                    total_problems_TRU_FACTORIZATION / total_number_problems,
                ),
            )
            push!(
                results_total,
                (
                    total,
                    total_problems_CAT_I_FACTORIZATION,
                    total_problems_CAT_II_FACTORIZATION,
                    total_problems_CAT_II_THETA_ZERO_FACTORIZATION,
                    total_problems_ARC_FACTORIZATION,
                    total_problems_TRU_FACTORIZATION,
                ),
            )
        end
    end

    return results_fraction
end

function plotFigureComparisonCAT(
    df::DataFrame,
    criteria::String,
    dirrectoryName::String,
    plot_name::String,
)
    data = Matrix(df[!, Not(criteria)])
    criteria_keyrword =
        criteria == "Functions" ? "function evaluations" : "gradient evaluations"
    plot(
        df[!, criteria],
        data,
        label = ["Our method (θ = 0.1)" "Our method (θ = 0.0)"],
        color = [CAT_II_FACTORIZATION_COLOR CAT_II_THETA_ZERO_FACTORIZATION_COLOR],
        ylabel = "Fraction of problems solved",
        xlabel = string("Total number of ", criteria_keyrword),
        legend = :bottomright,
        xlims = (10, ITR_LIMIT),
        xaxis = :log10,
    )
    yaxis!((0, 0.9), 0.1:0.1:0.9)
    fullPath = string(dirrectoryName, "/", plot_name)
    png(fullPath)
end

function generateFiguresComparisonCAT(dirrectoryName::String)
    fileName = "all_algorithm_results_functions_CAT.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    results = computeFraction_CAT(df, TOTAL_ITERATIONS, "Functions")
    results = results[
        :,
        filter(
            x -> (
                x in ["Functions", CAT_II_FACTORIZATION, CAT_II_THETA_ZERO_FACTORIZATION]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_total_functions_count_comparison_CAT.png"
    plotFigureComparisonCAT(results, "Functions", dirrectoryName, plot_name)

    fileName = "all_algorithm_results_gradients_CAT.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    results = computeFraction_CAT(df, TOTAL_ITERATIONS, "Gradients")
    results = results[
        :,
        filter(
            x -> (
                x in ["Gradients", CAT_II_FACTORIZATION, CAT_II_THETA_ZERO_FACTORIZATION]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_total_gradients_count_comparison_CAT.png"
    plotFigureComparisonCAT(results, "Gradients", dirrectoryName, plot_name)
end

function plotFiguresComparisonFinal(
    df::DataFrame,
    criteria::String,
    dirrectoryName::String,
    plot_name::String,
)
    data = Matrix(df[!, Not(criteria)])
    dict_ = Dict(
        "Functions" => "function evaluations",
        "Gradients" => "gradient evaluations",
        "Hessian" => "hessian evaluations",
        "Factorization" => "factorizations",
        "Time" => "seconds",
    )
    criteria_keyrword = dict_[criteria]
    LIMIT = criteria == "Time" ? TIME_LIMIT : ITR_LIMIT
    plot(
        df[!, criteria],
        data,
        label = ["Conference version of our method" "Our method" "ARC" "TRU"],
        color = [CAT_I_FACTORIZATION_COLOR CAT_II_FACTORIZATION_COLOR ARC_FACTORIZATION_COLOR TRU_FACTORIZATION_COLOR],
        ylabel = "Fraction of problems solved",
        xlabel = criteria == "Time" ? "Wall clock time (secs)" :
                 "Total number of $criteria_keyrword",
        legend = :bottomright,
        xlims = criteria == "Time" ? (0.1, LIMIT) : (10, LIMIT),
        xaxis = :log10,
    )
    if criteria == "Time"
        yaxis!((0, 0.9), 0.1:0.1:0.9)
        xticks!([10^-1, 10^0, 10^1, 10^2, 10^3, 10^4])
    else
        yaxis!((0, 0.9), 0.1:0.1:0.9)
    end
    fullPath = string(dirrectoryName, "/", plot_name)
    png(fullPath)
end

function generateFiguresIterationsComparisonFinal(dirrectoryName::String)
    fileName = "all_algorithm_results_functions.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    results = computeFraction(df, TOTAL_ITERATIONS, "Functions")
    results = results[
        :,
        filter(
            x -> (
                x in [
                    "Functions",
                    CAT_I_FACTORIZATION,
                    CAT_II_FACTORIZATION,
                    ARC_FACTORIZATION,
                    TRU_FACTORIZATION,
                ]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_total_functions_count_final.png"
    plotFiguresComparisonFinal(results, "Functions", dirrectoryName, plot_name)
end

function generateFiguresGradientsComparisonFinal(dirrectoryName::String)
    fileName = "all_algorithm_results_gradients.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    results = computeFraction(df, TOTAL_ITERATIONS, "Gradients")
    results = results[
        :,
        filter(
            x -> (
                x in [
                    "Gradients",
                    CAT_I_FACTORIZATION,
                    CAT_II_FACTORIZATION,
                    ARC_FACTORIZATION,
                    TRU_FACTORIZATION,
                ]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_total_gradients_count_final.png"
    plotFiguresComparisonFinal(results, "Gradients", dirrectoryName, plot_name)
end

function generateFiguresHessianComparisonFinal(dirrectoryName::String)
    fileName = "all_algorithm_results_hessian.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    results = computeFraction(df, TOTAL_ITERATIONS, "Hessian")
    results = results[
        :,
        filter(
            x -> (
                x in [
                    "Hessian",
                    CAT_I_FACTORIZATION,
                    CAT_II_FACTORIZATION,
                    ARC_FACTORIZATION,
                    TRU_FACTORIZATION,
                ]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_total_hessian_count_final.png"
    plotFiguresComparisonFinal(results, "Hessian", dirrectoryName, plot_name)
end

function generateFiguresFactorizationComparisonFinal(dirrectoryName::String)
    fileName = "all_algorithm_results_factorization.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    results = computeFraction(df, TOTAL_ITERATIONS, "Factorization")
    results = results[
        :,
        filter(
            x -> (
                x in [
                    "Factorization",
                    CAT_I_FACTORIZATION,
                    CAT_II_FACTORIZATION,
                    ARC_FACTORIZATION,
                    TRU_FACTORIZATION,
                ]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_total_factorization_count_final.png"
    plotFiguresComparisonFinal(results, "Factorization", dirrectoryName, plot_name)
end

function generateFiguresTimeComparisonFinal(dirrectoryName::String)
    fileName = "all_algorithm_results_time.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    df[!, CAT_I_FACTORIZATION] =
        replace!(df[!, CAT_I_FACTORIZATION], 18000.0 => 2 * 18000.0)
    df[!, CAT_II_FACTORIZATION] =
        replace!(df[!, CAT_II_FACTORIZATION], 18000.0 => 2 * 18000.0)
    df[!, ARC_FACTORIZATION] = replace!(df[!, ARC_FACTORIZATION], 18000.0 => 2 * 18000.0)
    df[!, TRU_FACTORIZATION] = replace!(df[!, TRU_FACTORIZATION], 18000.0 => 2 * 18000.0)
    results = computeFraction(df, TOTAL_TIME, "Time")
    results = results[
        :,
        filter(
            x -> (
                x in [
                    "Time",
                    CAT_I_FACTORIZATION,
                    CAT_II_FACTORIZATION,
                    ARC_FACTORIZATION,
                    TRU_FACTORIZATION,
                ]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_total_time_final.png"
    plotFiguresComparisonFinal(results, "Time", dirrectoryName, plot_name)
end

function plotFiguresComparisonObjFinal(
    df::DataFrame,
    criteria::String,
    dirrectoryName::String,
    plot_name::String,
)
    data = Matrix(df[!, Not(criteria)])
    plot(
        df[!, criteria],
        data,
        label = ["Conference version of our method" "Our method" "ARC" "TRU"],
        color = [CAT_I_FACTORIZATION_COLOR CAT_II_FACTORIZATION_COLOR ARC_FACTORIZATION_COLOR TRU_FACTORIZATION_COLOR],
        ylabel = "Fraction of problems",
        xlabel = "Objective difference from best",
        legend = :bottomright,
        xlims = (1e-6, 1e6),
        xaxis = :log10,
    )
    yaxis!((0.55, 1.0), 0.55:0.05:1.0)
    fullPath = string(dirrectoryName, "/", plot_name)
    png(fullPath)
end

function generateFiguresObjComparisonFinal(dirrectoryName::String)
    fileName = "all_algorithm_results_obj_value.csv"
    fullPath = string(dirrectoryName, "/", fileName)
    df = readFile(fullPath)
    results = computeFraction(df, TOTAL_OBJ_VECTOR, "Obj")
    results = results[
        :,
        filter(
            x -> (
                x in [
                    "Obj",
                    CAT_I_FACTORIZATION,
                    CAT_II_FACTORIZATION,
                    ARC_FACTORIZATION,
                    TRU_FACTORIZATION,
                ]
            ),
            names(results),
        ),
    ]
    plot_name = "fraction_of_problems_solved_versus_obj_final.png"
    plotFiguresComparisonObjFinal(results, "Obj", dirrectoryName, plot_name)
end

function format_to_six_decimals(x)
    str = @sprintf("%.6f", x)
    num = parse(Float64, str)
    return num
end

function plotAllFigures(dirrectoryName::String)
    generateFiguresComparisonCAT(dirrectoryName)
    generateFiguresIterationsComparisonFinal(dirrectoryName)
    generateFiguresGradientsComparisonFinal(dirrectoryName)
    generateFiguresHessianComparisonFinal(dirrectoryName)
    generateFiguresFactorizationComparisonFinal(dirrectoryName)
    generateFiguresTimeComparisonFinal(dirrectoryName)
    generateFiguresObjComparisonFinal(dirrectoryName)
end
