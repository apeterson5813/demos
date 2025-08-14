using Test

include("storageOptimization.jl");

# @testset "storageOptimization" begin
#     @testset "feasible solution" begin
#         testPrices = [1.0,1.0,1.0,1.0,2.0,2.0,2.0,2.0]
#         testConfig = StorageModelConfig(4, 1, roundTripEfficency=100);
#         sol = solveStorageOptimization(testPrices, testConfig)

#         @test isequal(sol.revenue, 4.0)
#         println(sol)
#     end

#     @testset "capacity bonus solution" begin
#         testPrices = [1.0,1.0,1.0,1.0,2.0,2.0,1.0,1.0]
#         testCapacityBonus = [0.0,0.0,0.0,0.0,0.0,0.0,3.0,3.0]
#         testConfig = StorageModelConfig(4, 1, roundTripEfficency=100);
#         sol = solveStorageOptimization(testPrices, testConfig; capacityBonus=testCapacityBonus)

#         @test isequal(sol.revenue, 8.0)
#         println(sol)
#     end
# end

# @testset "solveRollingStorageOptimization" begin
#     @testset "feasible solution" begin
#         testPrices = [1.0,1.0,2.0,2.0,1.0,1.0,2.0,2.0,1.0,1.0,2.0,2.0]
#         testConfig = StorageModelConfig(2, 1, roundTripEfficency=100);
#         sol = solveRollingStorageOptimization(testPrices, testConfig, 4, 1)

#         @test isequal(sol.revenue, 4.0)
#         println(sol)
#     end

#     @testset "capacity bonus solution" begin
#         testPrices = [1.0,1.0,2.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,2.0,1.0]
#         testCapacityBonus = [0.0,0.0,0.0,3.0,0.0,0.0,0.0,3.0,0.0,0.0,0.0,3.0]
#         testConfig = StorageModelConfig(2, 1, roundTripEfficency=100);
#         sol = solveRollingStorageOptimization(testPrices, testConfig, 4, 1; capacityBonus=testCapacityBonus)

#         @test isequal(sol.revenue, 8.0)
#         println(sol)
#     end
# end

@testset "hybridOptimization" begin
    @testset "feasible solution" begin
        testPrices = [1.0,1.0,1.0,1.0,2.0,2.0,2.0,2.0]
        testGeneration = [12.0,11.0,10.0,9.0,8.0,7.0,6.0,6.0]
        testInterconnectionLimit = 10.0
        testConfig = StorageModelConfig(4, 1, roundTripEfficency=100);

        sol = solveHybridSystemOptimization(testPrices, testConfig, testInterconnectionLimit, testGeneration)

        # @test isequal(sol.revenue, 4.0)
        # println(sol)

        res = parseSolution(sol)

        @show res
    end

    # @testset "capacity bonus solution" begin
    #     testPrices = [1.0,1.0,1.0,1.0,2.0,2.0,1.0,1.0]
    #     testGeneration = [12.0,11.0,10.0,9.0,8.0,7.0,6.0,6.0]
    #     testInterconnectionLimit = 10.0
    #     testCapacityBonus = [0.0,0.0,0.0,0.0,0.0,0.0,3.0,3.0]
    #     testConfig = StorageModelConfig(4, 1, roundTripEfficency=100);

    #     sol = solveHybridSystemOptimization(testPrices, testConfig, testInterconnectionLimit, testGeneration; capacityBonus=testCapacityBonus)

    #     @test isequal(sol.revenue, 8.0)
    #     println(sol)
    # end
end