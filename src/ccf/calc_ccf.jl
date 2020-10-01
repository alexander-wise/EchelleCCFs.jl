"""
    Code to compute CCFs
Author: Michael Palumbo
Created: December 2019
Contact: mlp95@psu.edu
Based on code by Alex Wise (aw@psu.edu)
Refactored and optimized by Eric Ford
"""

"""
    `ccf_1D!(ccf_out, λs, fluxes; ccf_plan )`

Compute the cross correlation function of a spectrum with a mask.
    Generalized version that should work with different mask shapes.
# Inputs:
- `ccf_out`: 1-d array of size length(calc_ccf_v_grid(plan)) to store output
- `λs`: 1-d array of wavelengths
- `fluxes`:  1-d array of fluxes
# Optional Arguments:
- `plan`:  parameters for computing ccf (BasicCCFPlan())
"""
function ccf_1D!(ccf_out::A1, λ::A2, flux::A3,
                plan::PlanT = BasicCCFPlan(); projection_workspace::AbstractArray{T4,2} = zeros(length(λ),1),
                assume_sorted::Bool = false ) where {
                T1<:Real, A1<:AbstractArray{T1,1}, T2<:Real, A2<:AbstractArray{T2,1}, T3<:Real, A3<:AbstractArray{T3,1}, T4<:Real,
                PlanT<:AbstractCCFPlan }
    # make sure wavelengths and spectrum are 1D arrays
    @assert ndims(λ) == 1
    @assert ndims(flux) == 1
    @assert length(λ) == length(flux)
    @assert assume_sorted || issorted( plan.line_list.λ )
    v_grid = calc_ccf_v_grid(plan)
    @assert size(ccf_out,1) == length(v_grid)

    if length(plan.line_list) < 1  # If no lines in chunk
        ccf_out .= zero(eltype(A1))
        return ccf_out
    end

    @assert size(projection_workspace,1) == length(λ)

    # loop through each velocity, project the mask and compute ccf at given v
    for i in 1:size(ccf_out,1)
        # project shifted mask on wavelength domain
        doppler_factor = calc_doppler_factor(v_grid[i])
        project_mask!(projection_workspace, λ, plan, shift_factor=doppler_factor)

        # compute the ccf value at the current velocity shift
        ccf_out[i] = sum(flux .* projection_workspace)
    end
    return ccf_out
end

"""
    `ccf_1D!(ccf_out, ccf_var_out, λs, fluxes, var; ccf_plan )`

Compute the cross correlation function of a spectrum with a mask.
    Generalized version that should work with different mask shapes.
# Inputs:
- `ccf_out`: 1-d array of size length(calc_ccf_v_grid(plan)) to store output
- `ccf_var_out`:  1-d array of size length(calc_ccf_v_grid(plan)) to store output
- `λs`: 1-d array of wavelengths
- `fluxes`:  1-d array of fluxes
- `var`:  1-d array of flux variances
# Optional Arguments:
- `plan`:  parameters for computing ccf (BasicCCFPlan())
"""
function ccf_1D!(ccf_out::A1, ccf_var_out::A1, λ::A2, flux::A3, var::A4,
                plan::PlanT = BasicCCFPlan(); projection_workspace::AbstractArray{T5,2} = zeros(length(λ),1),
                assume_sorted::Bool = false ) where {
                T1<:Real, A1<:AbstractArray{T1,1}, T2<:Real, A2<:AbstractArray{T2,1}, T3<:Real, A3<:AbstractArray{T3,1}, T4<:Real, A4<:AbstractArray{T4,1}, T5<:Real,
                PlanT<:AbstractCCFPlan }
    # make sure wavelengths and spectrum are 1D arrays
    @assert ndims(λ) == 1
    @assert ndims(flux) == 1
    @assert length(λ) == length(flux)
    @assert assume_sorted || issorted( plan.line_list.λ )
    v_grid = calc_ccf_v_grid(plan)
    @assert size(ccf_out,1) == size(ccf_var_out,1)
    @assert size(ccf_out,1) == length(v_grid)


    if length(plan.line_list) < 1  # If no lines in chunk
        ccf_out .= zero(eltype(A1))
        ccf_var_out .= zero(eltype(A1))
        return (ccf=ccf_out, ccf_var=ccf_var_out)
    end

    @assert size(projection_workspace,1) == length(λ)

    # loop through each velocity, project the mask and compute ccf at given v
    for i in 1:size(ccf_out,1)
        # project shifted mask on wavelength domain
        doppler_factor = calc_doppler_factor(v_grid[i])
        project_mask!(projection_workspace, λ, plan, shift_factor=doppler_factor)

        # compute the ccf value at the current velocity shift
        ccf_out[i] = sum(flux .* projection_workspace)
        ccf_var_out[i] = sum(var .* projection_workspace)
    end
    return (ccf=ccf_out, ccf_var=ccf_var_out)
end

"""
    `ccf_1D_exper!(ccf_out, ccf_var_out, λs, fluxes, vars; ccf_plan )`

Compute the cross correlation function of a spectrum with a mask.
    Generalized version that should work with different mask shapes.
    Weights each pixel by provided variance.
    WARNING: Still experimenting.  Needs testing.
# Inputs:
- `ccf_out`: 1-d array of size length(calc_ccf_v_grid(plan)) to store output
- `ccf_var_out`: 1-d array of size length(calc_ccf_v_grid(plan)) to store output
- `λs`: 1-d array of wavelengths
- `fluxes`:  1-d array of fluxes
- `var`:  1-d array of flux variances
# Optional Arguments:
- `plan`:  parameters for computing ccf (BasicCCFPlan())
"""
function ccf_1D_exper!(ccf_out::A1, ccf_var_out::A1, λ::A2, flux::A3, var::A4,
                plan::PlanT = BasicCCFPlan(); projection_workspace::AbstractArray{T5,2} = zeros(length(λ),1),
                assume_sorted::Bool = false ) where {
                T1<:Real, A1<:AbstractArray{T1,1}, T2<:Real, A2<:AbstractArray{T2,1}, T3<:Real, A3<:AbstractArray{T3,1}, T4<:Real, A4<:AbstractArray{T4,1}, T5<:Real,
                PlanT<:AbstractCCFPlan }
    # make sure wavelengths and spectrum are 1D arrays
    @assert ndims(λ) == 1
    @assert ndims(flux) == 1
    @assert ndims(var) == 1
    @assert length(λ) == length(flux) == length(var)
    @assert assume_sorted || issorted( plan.line_list.λ )
    v_grid = calc_ccf_v_grid(plan)
    @assert size(ccf_out,1) == length(v_grid)

    if length(plan.line_list) < 1  # If no lines in chunk
        ccf_out .= zero(eltype(A1))
        ccf_var_out .= zero(eltype(A1))
        return (ccf=ccf_out, ccf_var=ccf_var_out)
    end

    @assert size(projection_workspace,1) == length(λ)

    #medvar = median(var)
    # loop through each velocity, project the mask and compute ccf at given v
    for i in 1:size(ccf_out,1)
        # project shifted mask on wavelength domain
        doppler_factor = calc_doppler_factor(v_grid[i])
        project_mask!(projection_workspace, λ, plan, shift_factor=doppler_factor)
        var_of_segment = ones(length(projection_workspace))
        on_mask = projection_workspace[1] > 0 ? true : false
        segment_start = 1
        n_in_mask_segment = on_mask ? 1 : 0
        sum_var_in_mask_segment = var[1]
        for i in 2:length(projection_workspace)
            if !on_mask
                if projection_workspace[i] != 0.0
                    segment_start = i
                    n_in_mask_segment = 1
                    sum_var_in_mask_segment = var[i]
                    on_mask = true
                end
            else         # on_mask
                if  projection_workspace[i] != 0.0
                    n_in_mask_segment += 1
                    sum_var_in_mask_segment += var[i]
                else    # projection_workspace[i] == 0.0
                    var_of_segment[segment_start:i-1] .= sum_var_in_mask_segment/n_in_mask_segment
                    on_mask = false
                end
            end
        end
        if on_mask
            var_of_segment[segment_start:end] .= sum_var_in_mask_segment/n_in_mask_segment
        end
        # compute the ccf value at the current velocity shift
        ccf_out[i] = sum(projection_workspace .* flux )
        ccf_var_out[i] = sum(projection_workspace .* var_of_segment  )
        #ccf_out[i] = sum(projection_workspace .* ( (flux.-1)  ))
        #ccf_out[i] = sum(projection_workspace .* ( (flux.-1) ./ var) )
    end
    return (ccf=ccf_out, ccf_var=ccf_var_out)
end
    #=
    best_i = argmin(ccf_out)
    doppler_factor = calc_doppler_factor(v_grid[best_i])
    project_mask!(projection_workspace, λ, plan, shift_factor=doppler_factor)
    global projection_mask_from_ccf1D = copy(projection_workspace)

    var_of_segment = ones(length(projection_workspace))
    on_mask = projection_workspace[1] > 0 ? true : false
    segment_start = 1
    n_in_mask_segment = on_mask ? 1 : 0
    sum_var_in_mask_segment = var[1]
    for i in 2:length(projection_workspace)
        if !on_mask && projection_workspace[i] != 0.0
            segment_start = i
            n_in_mask_segment = 1
            sum_var_in_mask_segment = var[i]
            on_mask = true
        end
        if on_mask && projection_workspace[i] != 0.0
            n_in_mask_segment += 1
            sum_var_in_mask_segment += var[i]
        end

        if on_mask && projection_workspace[i] == 0.0
            var_of_segment[segment_start:i-1] .= sum_var_in_mask_segment/n_in_mask_segment
            on_mask = false
        end
    end
    global var_of_segment_from_ccf1D = copy(var_of_segment)
    #ccf_out .*= 1/sqrt( sum(abs2.(flux)./ var))
    #=
    doppler_factor = calc_doppler_factor(plan.v_center)
    project_mask!(projection_workspace, λ, plan, shift_factor=doppler_factor)
    mask_norm = sqrt(sum(abs2.(projection_workspace ./ var)))
    flux_norm = sqrt(sum(abs2.(flux  ./ var )))
    # Account for mask not being normalized to fluxes
    ccf_out .*= ccf_out
    if(mask_norm>0)
        ccf_out ./= mask_norm^2
    end
    if(flux_norm>0)
        ccf_out ./= flux_norm^2
    end
    =#
    #ccf_out .*= 1/sqrt(sum(abs2.(projection_workspace)./ var) * sum(abs2.(flux)./ var))
    #mask_norm = sqrt(mean(abs2.(projection_workspace) ))
    #flux_norm = sqrt(mean(abs2.(flux)  ))
    sum_inv_var = sum(1 ./ var_of_segment)
    ccf_out ./= sum_inv_var
    mask_norm = sqrt(sum(abs2.(projection_workspace) ./ var_of_segment) / sum_inv_var )
    flux_norm = sqrt(sum(abs2.(flux)  ./ var_of_segment ) / sum_inv_var )
    #=
    sum_inv_var = sum(1 ./ var)
    ccf_out ./= sum_inv_var
    mask_norm = sqrt(sum(abs2.(projection_workspace) ./ var) / sum_inv_var )
    flux_norm = sqrt(sum(abs2.(flux)  ./ var ) / sum_inv_var )
    =#
    # Account for mask not being normalized to fluxes
    if(mask_norm>0)
        ccf_out ./= mask_norm
    end
    if(flux_norm>0)
        ccf_out ./= flux_norm
    end
    #ccf_out ./= length(flux)
    #weightsum =  sum(1.0 ./ var)
    #ccf_out ./= weightsum
    #ccf_out .*= mean(flux)
    return (ccf=ccf_out, ccf_var=ccf_var_out)
end
    =#


"""
    `ccf_1D( λs, fluxes; ccf_plan )`
    Compute the cross correlation function of a spectrum with a mask.
# Inputs:
- `λs`: 1-d array of wavelengths
- `fluxes`:  1-d array of fluxes
# Optional Arguments:
- `ccf_plan`:  parameters for computing ccf (BasicCCFPlan())
# Returns:
- 1-d array of size length(calc_ccf_v_grid(plan))
"""
function ccf_1D(λ::A2, flux::A3, #line_list::ALL, #mask_shape1::A3
                plan::PlanT = BasicCCFPlan() ) where {
                #; mask_shape::ACMS = TopHatCCFMask(), plan::PlanT = BasicCCFPlan() ) where {
                T1<:Real, A1<:AbstractArray{T1,1}, T2<:Real, A2<:AbstractArray{T2,1}, T3<:Real, A3<:AbstractArray{T3,1},
                #ALL<:AbstractLineList, ACMS<:AbstractCCFMaskShape, AP<:AbstractCCFPlan }
                PlanT<:AbstractCCFPlan } # ALL<:AbstractLineList, ACMS<:AbstractCCFMaskShape }
    @assert ndims(λ) == 1
    @assert ndims(flux) == 1
    @assert length(λ) == length(flux)
    len_v_grid = calc_length_ccf_v_grid(plan)
    ccf_out = zeros(len_v_grid)
    if length(plan.line_list) < 1  # If no lines in chunk
        return ccf_out
    end
    ccf_1D!(ccf_out, λ, flux, plan )
    return ccf_out
end

"""
    `ccf_1D( λs, fluxes, vars; ccf_plan )`

Compute the cross correlation function of a spectrum with a mask and its variance.
    This version uses pixel variances.
    WARNING: Still experimenting.  Needs testing.
# Inputs:
- `λs`: 1-d array of wavelengths
- `fluxes`:  1-d array of fluxes
# Optional Arguments:
- `ccf_plan`:  parameters for computing ccf (BasicCCFPlan())
# Returns:
- 1-d array of size length(calc_ccf_v_grid(plan))
"""
function ccf_1D(λ::A2, flux::A3, var::A4,
                plan::PlanT = BasicCCFPlan() ) where {
                #; mask_shape::ACMS = TopHatCCFMask(), plan::PlanT = BasicCCFPlan() ) where {
                T1<:Real, A1<:AbstractArray{T1,1}, T2<:Real, A2<:AbstractArray{T2,1}, T3<:Real, A3<:AbstractArray{T3,1}, T4<:Real, A4<:AbstractArray{T4,1},
                #ALL<:AbstractLineList, ACMS<:AbstractCCFMaskShape, AP<:AbstractCCFPlan }
                PlanT<:AbstractCCFPlan } # ALL<:AbstractLineList, ACMS<:AbstractCCFMaskShape }
    @assert ndims(λ) == 1
    @assert ndims(flux) == 1
    @assert length(λ) == length(flux)
    len_v_grid = calc_length_ccf_v_grid(plan)
    ccf_out = zeros(len_v_grid)
    ccf_var_out = zeros(len_v_grid)
    if length(plan.line_list) < 1  # If no lines in chunk
        return (ccf=ccf_out , ccf_var=ccf_var_out)
    end
    ccf_1D!(ccf_out, ccf_var_out, λ, flux, var, plan )
    return (ccf=ccf_out , ccf_var=ccf_var_out)
end

""" `project_mask!( output, λs, ccf_plan; shift_factor )`

Compute the projection of the mask onto the 1D array of wavelengths (λs) at a given shift factor (default: 1).
The mask is computed from the ccf_plan, including a line_list and mask_shape (default: tophat).
Assumes plan.line_list is already sorted.

"""
function project_mask!(projection::A2, λs::A1, plan::PlanT ; shift_factor::Real=one(T1)
                            ) where { T1<:Real, A1<:AbstractArray{T1,1}, T2<:Real, A2<:AbstractArray{T2,2}, A3<:AbstractArray{T1,1}, PlanT<:AbstractCCFPlan }
    num_lines_in_mask = length(plan.line_list)
    @assert num_lines_in_mask >= 1
    @assert size(projection,1) == length(λs)
    projection .= zero(eltype(projection))  # Important to zero out projection before accumulating there!

    # set indexing variables
    p = 1
    p_left_edge_of_current_line = 1
    λsle_cur = λs[p]-0.5*(λs[p+1]-λs[p])   # Current pixel's left edge
    λsre_cur = 0.5*(λs[p]+λs[p+1])   # Current pixel's left edge
    #@assert issorted( plan.line_list.λ )  # Moved outside of inner loop
    m = searchsortedfirst(plan.line_list.λ, λsle_cur/shift_factor)
    while m <= length(plan.line_list.λ) && λ_min(plan.mask_shape,plan.line_list.λ[m]) * shift_factor < λsle_cur   # only includemask entry if it fit entirely in chunk
        m += 1
    end
    if m >= length(plan.line_list.λ)   # Return early if no lines fall within chunk's lambda's
        return projection
    else
        #println("# Starting with mask entry at λ=", plan.line_list.λ[m], " for chunk with λ= ",first(λs)," - ",last(λs))
    end
    on_mask = false
    mask_mid = plan.line_list.λ[m] * shift_factor
    mask_lo = λ_min(plan.mask_shape,plan.line_list.λ[m]) * shift_factor   # current line's lower limit
    mask_hi = λ_max(plan.mask_shape,plan.line_list.λ[m]) * shift_factor   # current line's upper limit

    c_mps = speed_of_light_mps
    mask_weight = plan.line_list.weight[m]
    # loop through lines in mask, weight mask by fraction of PSF falling in each wavelength bin and divide by Δlnλ for pixel
    while m <= num_lines_in_mask
        if !on_mask
            if λsre_cur > mask_lo
                if λsre_cur > mask_hi   # Pixel overshot this mask entry, so weight based on mask filling only a portion of the pixel,
                    #For Tophat: projection[p] += mask_weight * (mask_hi - mask_lo) / (λsre_cur - λsle_cur)
                    #frac_of_psf_in_v_pixel = 1.0
                    one_over_delta_z_pixel = 0.5*(λsre_cur + λsle_cur) / (λsre_cur - λsle_cur)
                    projection[p] += one_over_delta_z_pixel * mask_weight
                    m += 1
                    if m<=length(plan.line_list)      # Move to next line
                        mask_mid = plan.line_list.λ[m] * shift_factor
                        mask_lo = λ_min(plan.mask_shape,plan.line_list.λ[m]) * shift_factor
                        mask_hi = λ_max(plan.mask_shape,plan.line_list.λ[m]) * shift_factor
                        mask_weight = plan.line_list.weight[m]
                    else         # We're out of lines, so exit
                        break
                    end
                else                       # Right edge of current pixel has entered the mask for this line, but left edge hasn't
                    #For Tophat: projection[p] += mask_weight * (λsre_cur - mask_lo) / (λsre_cur - λsle_cur)
                    frac_of_psf_in_v_pixel = integrate(plan.mask_shape, (mask_lo-mask_mid)/mask_mid*c_mps, (λsre_cur-mask_mid)/mask_mid*c_mps)
                    one_over_delta_z_pixel = 0.5*(λsre_cur + λsle_cur) / (λsre_cur - λsle_cur)
                    projection[p] += frac_of_psf_in_v_pixel * one_over_delta_z_pixel * mask_weight
                    on_mask = true         # Indicate next pixel will hav something to contribute based on the current line
                    p_left_edge_of_current_line = p                 # Mark the starting pixel of the line in case the lines overlap
                    p+=1                   # Move to next pixel
                    λsle_cur = λsre_cur   # Current pixel's left edge
                    λsre_cur = p<length(projection) ? 0.5*(λs[p]+λs[p+1]) : λs[p]+0.5*(λs[p]-λs[p-1])    # Current pixel's right edge

                end
            else   # ALl of pixel is still to left of beginning of mask for this line.
                p+=1    # TODO: Opt try to accelerate with something like searchsortedfirst?  Probably not worth it.
                λsle_cur = λsre_cur   # Current pixel's left edge
                λsre_cur = p<length(projection) ? 0.5*(λs[p]+λs[p+1]) : λs[p]+0.5*(λs[p]-λs[p-1])    # Current pixel's right edge
            end
        else
            if λsre_cur > mask_hi               # Right edge of this pixel moved past the edge of the current line's mask
                #For Tophat: projection[p] += mask_weight * (mask_hi - λsle_cur) / (λsre_cur - λsle_cur)
                frac_of_psf_in_v_pixel = integrate(plan.mask_shape, (λsle_cur-mask_mid)*c_mps/mask_mid, (mask_hi-mask_mid)*c_mps/mask_mid)
                one_over_delta_z_pixel = 0.5*(λsre_cur + λsle_cur) / (λsre_cur - λsle_cur)
                projection[p] += frac_of_psf_in_v_pixel * one_over_delta_z_pixel * mask_weight
                on_mask = false                 # Indicate that we're done with this line
                m += 1                          # Move to next line
                if m<=length(plan.line_list)
                    mask_mid = plan.line_list.λ[m] * shift_factor
                    mask_lo = λ_min(plan.mask_shape,plan.line_list.λ[m]) * shift_factor
                    mask_hi = λ_max(plan.mask_shape,plan.line_list.λ[m]) * shift_factor
                    mask_weight = plan.line_list.weight[m]
                    if mask_lo < λsle_cur       # If the lines overlap, we may have moved past the left edge of the new line. In that case go back to the left edge of the previous line.
                        p = p_left_edge_of_current_line
                        λsle_cur = p>1 ? 0.5*(λs[p]+λs[p-1]) : λs[p]-0.5*(λs[p+1]-λs[p])   # Current pixel's left edge
                        λsre_cur = 0.5*(λs[p]+λs[p+1])   # Current pixel's right edge
                    end

                else                            # We're done with all lines, can return early
                    break
                end
            else                                # This pixel is entirely within the mask
                # assumes plan.mask_shape is normalized to integrate to unity and flux is constant within pixel
                #For Tophat: projection[p] += mask_weight    # Add the full mask weight
                frac_of_psf_in_v_pixel = integrate(plan.mask_shape, (λsle_cur-mask_mid)/mask_mid*c_mps, (λsre_cur-mask_mid)/mask_mid*c_mps)
                one_over_delta_z_pixel = 0.5*(λsre_cur + λsle_cur) / (λsre_cur - λsle_cur)
                projection[p] += frac_of_psf_in_v_pixel * one_over_delta_z_pixel * mask_weight
                p += 1                          # move to next pixel
                λsle_cur = λsre_cur   # Current pixel's left edge
                λsre_cur = p<length(projection) ? 0.5*(λs[p]+λs[p+1]) : λs[p]+0.5*(λs[p]-λs[p-1])    # Current pixel's right edge
            end
        end
        if p>length(projection) break end       # We're done with all pixels in this chunk.
    end
    projection ./= c_mps
    return projection
end