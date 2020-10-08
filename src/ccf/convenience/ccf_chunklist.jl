"""
    Code for convenience functions for calculating CCFs for an AbstractChunkList (see RvSpectMLBase)
Author: Eric Ford
Created: August 2020
"""

"""  `calc_ccf_chunklist ( chunklist, ccf_plans )`
Convenience function to compute CCF based on a spectrum's chunklist.
# Inputs:
- chunklist
- vector of ccf plans (one for each chunk)
# Optional Arguments:
- `assume_sorted`:  if true, skips checking the line_list is sorted by wavelength
# Return:
CCF summed over all chunks in a spectrum's chunklist, evaluated using the
line list and mask_shape from the ccf plan for each chunk.
"""
function calc_ccf_chunklist(chunk_list::AbstractChunkList,
                                plan_for_chunk::AbstractVector{PlanT};
                                assume_sorted::Bool = false #=, use_pixel_vars::Bool = false =#  ) where {
                                            PlanT<:AbstractCCFPlan }
  @assert length(chunk_list) == length(plan_for_chunk)
  mapreduce(chid->calc_ccf_chunk(chunk_list.data[chid], plan_for_chunk[chid],
                    assume_sorted=assume_sorted #=, use_pixel_vars=use_pixel_vars =#), +, 1:length(chunk_list.data) )
end


"""  `calc_ccf_and_var_chunklist ( chunklist, ccf_plans )`
Convenience function to compute CCF based on a spectrum's chunklist.
# Inputs:
- chunklist
- vector of ccf plans (one for each chunk)
# Optional Arguments:
- `assume_sorted`:  if true, skips checking the line_list is sorted by wavelength
# Return:
CCF summed over all chunks in a spectrum's chunklist, evaluated using the
line list and mask_shape from the ccf plan for each chunk.
"""
function calc_ccf_and_var_chunklist(chunk_list::AbstractChunkList,
                                plan_for_chunk::AbstractVector{PlanT};
                                assume_sorted::Bool = false #=, use_pixel_vars::Bool = false =#  ) where {
                                            PlanT<:AbstractCCFPlan }
  @assert length(chunk_list) == length(plan_for_chunk)
  (ccf_out, ccf_var_out ) = mapreduce(chid->calc_ccf_and_var_chunk(chunk_list.data[chid], plan_for_chunk[chid],
                    assume_sorted=assume_sorted #=, use_pixel_vars=use_pixel_vars =# ), add_tuple_sum, 1:length(chunk_list.data) )
  return (ccf=ccf_out, ccf_var=ccf_var_out)
end


#=
"""  `calc_ccf_chunklist ( chunklist, var_list, ccf_plans )`
Convenience function to compute CCF based on a spectrum's chunklist.
Prototype/Experimental version trying to use pixel variances not yet fully implemented/tested.
# Inputs:
- chunklist
- var_list: vector of variance vectors for each chunk
- ccf_palns: vector of ccf plans (one for each chunk)
# Optional Arguments:
# Return:
CCF summed over all chunks in a spectrum's chunklist, evaluated using the
line list and mask_shape from the ccf plan for each chunk.
"""
function calc_ccf_chunklist(chunk_list::AbstractChunkList, var_list::AbstractVector{A1},
                                plan_for_chunk::AbstractVector{PlanT};
                                assume_sorted::Bool = false, use_pixel_vars::Bool = false   ) where {
                                            T1<:Real, A1<:AbstractVector{T1}, PlanT<:AbstractCCFPlan }
  @assert length(chunk_list) == length(plan_for_chunk)
  @assert length(chunk_list) == length(var_list)
  @assert all(map(chid->length(chunk_list.data[chid].var) == length(var_list[chid]),1:length(chunk_list.data)))
  #var_weight = mapreduce(chid->median(chunk_list.data[chid].var), +, 1:length(chunk_list.data) ) / mapreduce(chid->median(var_list[chid]), +, 1:length(chunk_list.data) )
  var_weight = 1.0 #mapreduce(chid->mean(chunk_list.data[chid].var), +, 1:length(chunk_list.data) ) / mapreduce(chid->mean(var_list[chid]), +, 1:length(chunk_list.data) )
  #println("# var_weight*N_obs = ", var_weight .* length(chunk_list))
  mapreduce(chid->calc_ccf_chunk(chunk_list.data[chid], plan_for_chunk[chid], var=var_list[chid] .* var_weight,
                    assume_sorted=assume_sorted, #= use_pixel_vars=use_pixel_vars), =# +, 1:length(chunk_list.data) )
end
=#