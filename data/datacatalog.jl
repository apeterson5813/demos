using Dates
using TimeZones


struct Dataset
    path::String
    dateformat::String
    schema::Dict{Symbol, Any}
end

# region = @enum Region NORTH SOUTH CENTRAL NO_REGION

misoDADemandByRegion = Dataset(
    "",
    "",
    Dict(
        :date => DateTime,
        :region => String,
        :fixed => Float64,
        :priceSens => Float64,
        :virtual => Float64
    )
)

misoDAPriceByHub = Dataset(
    "",
    "yyyy-mm-ddTHH:MM:SS.s",
    Dict(
        :interval_start_est => DateTime,
        :interval_end_est => DateTime,
        :node => String,
        :lmp => Float64
    )
)

misoRTEnergyPrice = Dataset(
    "",
    "yyyy-mm-ddTHH:MM:SSzzzz",
    Dict(
        :interval_start_local => ZonedDateTime,
        :interval_start_utc => ZonedDateTime,
        :interval_end_local => ZonedDateTime,
        :interval_end_utc => ZonedDateTime,
        :market => String,
        :location => String,
        :location_type => String,
        :lmp => Float64,
        :energy => Float64,
        :congestion => Float64,
        :loss => Float64
    )
)

ercotDAEnergyPrice = Dataset(
    "",
    "yyyy-mm-ddTHH:MM:SSzzzz",
    Dict(
        :interval_start_local => ZonedDateTime,
        :interval_start_utc => ZonedDateTime,
        :interval_end_local => ZonedDateTime,
        :interval_end_utc => ZonedDateTime,
        :location => String,
        :location_type => String,
        :market => String,
        :spp => Float64
    )
)

caisoDAEnergyPrice = Dataset(
    "",
    "yyyy-mm-ddTHH:MM:SSzzzz",
    Dict(
        :interval_start_local => ZonedDateTime,
        :interval_start_utc => ZonedDateTime,
        :interval_end_local => ZonedDateTime,
        :interval_end_utc => ZonedDateTime,
        :market => String,
        :location => String,
        :location_type => String,
        :lmp => Float64,
        :energy => Float64,
        :congestion => Float64,
        :loss => Float64
    )
)

misoFuelMixByRegion = Dataset(
    "",
    "yyyy-mm-ddTHH:MM:SS.s",
    Dict(
        :interval_start_est => DateTime,
        :interval_end_est => DateTime,
        :region => String,
        :fuel_type => String,
        :da_cleared_uds_generation => Float64,
        :rt_generation_state_estimator => Float64
    )
)