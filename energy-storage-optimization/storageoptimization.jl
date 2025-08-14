using JuMP
# using GLPK
using Gurobi
using DataFramesMeta

"""
Struct for setting up storage optimization parameters
"""
struct StorageModelConfig
    energyCapacity::Int64
    powerRating::Int64
    roundTripEfficency::Int64
    selfDischarge::Int64

    function StorageModelConfig(energyCapacity::Int64, powerRating::Int64; roundTripEfficency::Int64=100, selfDischarge::Int64=0)
        if energyCapacity < 0
            throw(DomainError("Energy Capacity cannot be negative"))
        end
        if powerRating < 0
            throw(DomainError("Power Rating cannot be negative"))
        end
        if roundTripEfficency < 0 || roundTripEfficency > 100
            throw(DomainError("Round Trip Efficency must be between 0 and 100"))
        end
        if selfDischarge < 0 || selfDischarge > 100
            throw(DomainError("Self Discharge must be between 0 and 100"))
        end
        return new(energyCapacity, powerRating, roundTripEfficency, selfDischarge)
    end
end

"""
Struct for storing storage optimization results
"""
struct StorageOptimizationSolution
    status::TerminationStatusCode
    revenue::Float64
    prices::Vector{Float64}
    discharge::Vector{Float64}
    charge::Vector{Float64}
    soc::Vector{Float64}
end

"""
Struct for storing hybrid system optimization results
"""
struct HybridSystemOptimizationSolution
    status::TerminationStatusCode
    revenue::Float64
    prices::Vector{Float64}
    discharge::Vector{Float64}
    charge::Vector{Float64}
    soc::Vector{Float64}
    generation::Vector{Float64}
    exports::Vector{Float64}
    curtailment::Vector{Float64}
end


"""
Convert a optimization solution into a DataFrame for analysis
"""
function parseSolution(solution::StorageOptimizationSolution)
    output = DataFrame(
        price=solution.prices,
        charging=solution.charge,
        discharging=solution.discharge,
        SOCstart=solution.soc,
        SOCend=solution.soc + solution.charge - solution.discharge,
        cashFlow=(solution.prices .* solution.discharge) + ((-1 .* solution.prices) .* solution.charge),
    )
    @transform! output :cumulativeRevenue = cumsum(:cashFlow)
    return (output)
end

function parseSolution(solution::HybridSystemOptimizationSolution)
    output = DataFrame(
        price=solution.prices,
        genration=solution.generation,
        charging=solution.charge,
        discharging=solution.discharge,
        SOCstart=solution.soc,
        SOCend=solution.soc + solution.charge - solution.discharge,
        exports=solution.exports,
        curtailment=solution.curtailment,
        cashFlow=(solution.prices .* solution.exports) #+ ((-1 .* solution.prices) .* solution.charge),
    )
    @transform! output :cumulativeRevenue = cumsum(:cashFlow)
    return (output)
end

"""
Optimize storage dispatch to maximize revenue over the entire time horizon
"""
function solveStorageOptimization(prices::Vector{Float64}, config::StorageModelConfig; socStart::Float64=0.0, capacityBonus::Vector{Float64}=zeros(length(prices)))
    N = length(prices)
    hours = [i for i = 1:N]

    # m = Model(GLPK.Optimizer)
    m = Model(Gurobi.Optimizer)

    @variable(m, charge[hours] >= 0)
    @variable(m, discharge[hours] >= 0)
    @variable(m, 0 <= soc[hours] <= config.energyCapacity)

    # @objective(
    #     m, 
    #     Max, 
    #     sum((prices[i] * discharge[i]) - (prices[i] * charge[i]) for i in 1:N)
    # )
    #ToDo: hurdle price, DART optimization, anxillary services optimization
    @objective(
        m,
        Max,
        sum(
            (prices[i] * discharge[i])
            -
            (prices[i] * charge[i])
            +
            (capacityBonus[i] * (discharge[i] / config.powerRating))
            for i in 1:N
        )
    )

    @constraint(m, soc[1] == socStart)
    for h in hours[1:N]
        @constraint(m, discharge[h] <= soc[h])
        @constraint(m, charge[h] <= config.energyCapacity - soc[h])
        @constraint(m, charge[h] + discharge[h] <= config.powerRating)
        @constraint(m, 0 <= soc[h] <= config.energyCapacity)
        if (h != N)
            @constraint(
                m,
                soc[h+1] == ((100 - config.selfDischarge) / 100 * soc[h]) + (config.roundTripEfficency / 100 * charge[h]) - discharge[h]
            )
        end
    end

    optimize!(m)
    @assert is_solved_and_feasible(m)

    solution = StorageOptimizationSolution(
        termination_status(m),
        objective_value(m),
        prices,
        JuMP.value.(discharge).data,
        JuMP.value.(charge).data,
        JuMP.value.(soc).data
    )
    return (solution)
end

"""
Optimize hybrid (usually wind or solar paired with storage) dispatch to maximize revenue over the entire time horizon
"""
function solveHybridSystemOptimization(
    prices::Vector{Float64},
    config::StorageModelConfig,
    interconnectionLimit::Float64,
    generation::Vector{Float64};
    socStart::Float64=0.0,
    capacityBonus::Vector{Float64}=zeros(length(prices))
)
    N = length(prices)
    hours = [i for i = 1:N]

    # m = Model(GLPK.Optimizer)
    m = Model(Gurobi.Optimizer)

    @variable(m, charge[hours] >= 0)
    @variable(m, discharge[hours] >= 0)
    @variable(m, 0 <= soc[hours] <= config.energyCapacity)
    @variable(m, exports[hours] >= 0)
    @variable(m, curtailment[hours] >= 0)

    @objective(
        m,
        Max,
        sum(
            (prices[i] * exports[i])
            # -
            # (prices[i] * imports[i])
            +
            (capacityBonus[i] * (exports[i] / interconnectionLimit))
            for i in 1:N
        )
    )

    @constraint(m, soc[1] == socStart)
    for h in hours[1:N]
        @constraint(m, discharge[h] <= soc[h])
        @constraint(m, charge[h] <= config.energyCapacity - soc[h])
        @constraint(m, charge[h] + discharge[h] <= config.powerRating)
        @constraint(m, 0 <= soc[h] <= config.energyCapacity)

        @constraint(m, exports[h] == generation[h] + discharge[h] - charge[h] - curtailment[h])
        @constraint(m, exports[h] <= interconnectionLimit)
        if (h != N)
            @constraint(
                m,
                soc[h+1] == ((100 - config.selfDischarge) / 100 * soc[h]) + (config.roundTripEfficency / 100 * charge[h]) - discharge[h]
            )
        end
    end

    optimize!(m)
    @assert is_solved_and_feasible(m)

    solution = HybridSystemOptimizationSolution(
        termination_status(m),
        objective_value(m),
        prices,
        JuMP.value.(discharge).data,
        JuMP.value.(charge).data,
        JuMP.value.(soc).data,
        generation,
        JuMP.value.(exports).data,
        JuMP.value.(curtailment).data
    )
    return (solution)
end

"""
Optimize storage dispatch to maximize revenue based on a specificed forecast duration. 

Dispatach is optimized one period a time with the ability to lookahead based on the forecastLength.

Timeseries data should be longer than analysis period as periods without sufficient forecasts are discarded.
"""
function solveRollingStorageOptimization(prices::Vector{Float64}, config::StorageModelConfig, periodLength::Int64, forecastLength::Int64; socStart::Float64=0.0, capacityBonus::Vector{Float64}=zeros(length(prices)))
    @assert length(prices) % periodLength == 0
    @assert length(prices) >= periodLength + forecastLength

    finalSolutionHourStart = length(prices) - forecastLength
    socCur = socStart

    allSolutions = Vector{StorageOptimizationSolution}()

    for solutionHourStart = 1:periodLength:finalSolutionHourStart
        # modifiedCapacityBonus = vcat(capacityBonus[solutionHourStart:solutionHourStart+71][1:24], zeros(48)) # force storage to prioritize "todays" RA hours
        solution = solveStorageOptimization(
            prices[solutionHourStart:solutionHourStart+periodLength+forecastLength-1],
            config;
            socStart=socCur,
            capacityBonus=capacityBonus[solutionHourStart:solutionHourStart+periodLength+forecastLength-1])
        push!(allSolutions, solution)
        socCur = solution.soc[periodLength]
    end

    compiledDischarge = reduce(vcat, [sol.discharge[1:periodLength] for sol in allSolutions])
    compiledCharge = reduce(vcat, [sol.charge[1:periodLength] for sol in allSolutions])
    compiledSoc = reduce(vcat, [sol.soc[1:periodLength] for sol in allSolutions])

    revenue = sum([sum((sol.prices[1:periodLength] .* sol.discharge[1:periodLength]) + ((-1 .* sol.prices[1:periodLength]) .* sol.charge[1:periodLength])) for sol in allSolutions])

    compiledSolution = StorageOptimizationSolution(JuMP.OPTIMAL, revenue, prices[1:end-forecastLength], compiledDischarge, compiledCharge, compiledSoc)

    return compiledSolution
end
