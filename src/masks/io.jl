"""
Code for creating, loading and maniuplating line lists and masks.

Author: Eric Ford
Created: August 2020
"""

using DataFrames, CSV

"""
    Read line list in ESPRESSO csv format.
ESPRESSO format: lambda and weight.
Warning: ESPRESSO masks don't provide line depth and sometimes include one entry for a blend of lines.
"""
function read_linelist_espresso(fn::String)
    local df = CSV.read(fn,DataFrame,threaded=false,header=["lambda","weight"],delim=' ',ignorerepeated=true)
    @assert hasproperty(df, :lambda)
    @assert hasproperty(df, :weight)
    df[!,:lambda] .= λ_air_to_vac.(df[!,:lambda])
    return df
end

""" Read line list in VALD csv format.
   VALD format: lambda_lo, lambdaa_hi and depth.
"""
function read_linelist_vald(fn::String)
    local df = CSV.read(fn,DataFrame,threaded=false,header=["lambda_lo","lambda_hi","depth"])
    @assert hasproperty(df, :lambda_lo)
    @assert hasproperty(df, :lambda_hi)
    @assert hasproperty(df, :depth)
    df[!,:lambda_lo] .= λ_air_to_vac.(df[!,:lambda_lo])
    df[!,:lambda_hi] .= λ_air_to_vac.(df[!,:lambda_hi])
    df[!,:lambda] = sqrt.(df[!,:lambda_lo].*df[!,:lambda_hi])
    df[!,:weight] = df[!,:depth] # TODO: Decide out what we want to do about tracking depths and weights sepoarately
    return df
end