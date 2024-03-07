using Pkg
Pkg.activate(".")

using DataFrames 
using DataFramesMeta
using CSV
using MixedModels
using GLM
using IterTools
using CategoricalArrays
using MLJ
using Random
using RCall
using Serialization
using DynamicPipe


# Bring in my pseudo broom tidy function
include("utils.jl")

Random.seed!(336)

# Call R to do some work. In theory more cleaning if needed.

R"""
library(tidyverse)
library(data.table)
library(here)

# bring in the data------------------------------------------

dat_raw <- fread(here("data", "my_data.csv"))

# I normally do some more advanced wrangling PRN

"""
# Pull the R object into julia
@rget dat_raw

# There are some ways to coerce the levels to what are needed.
# occassionally the factors from R don't come over right
# I modified in place because it was easy.

function prep_data!(dat)
  levels!(dat.fu_period, ["0-4","5-12", "13-20", "21-28"])
  return dat
end

prep_data!(dat_raw)

# Fit a few logistic models 

simp_int = fit(MixedModel, @formula(y ~predictor*fu_period + (1|study_id)), 
                dat_raw, Bernoulli())

simp_no_int = fit(MixedModel, @formula(y ~predictor + fu_period + (1|study_id)), 
                dat_raw, Bernoulli())

lrtest(simp_int, simp_no_int)

# I combined all of my tidied tables....

outcomes = vcat(
tidy(simp_int, "Interactions", "true"),
tidy(simp_no_int, "No interactions", "true")
)

CSV.write(joinpath("results","tab_simple.csv"),outcomes)
