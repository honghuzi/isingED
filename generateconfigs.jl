#=
This code reads a FOO.jld generated by isingED.jl, generates N random
spin chain measurements in the computational basis, and saves them to 
a text file FOO.out.
=#

using ArgParse, LinearMaps, HDF5, JLD, EllipsisNotation

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
      "--infilename", "-i"
        help =  "Path to the .jld where the wavefunction is stored."
        arg_type = AbstractString
        required = true
      "-N"
        help = "Number of configurations to generate."
        arg_type = Int
        default = 20
      "--overwrite"
        help = "If infilename.out already exists and this flag is set it will
                be overwritten (by default it will be appended to)."
        action = :store_true

    end
    return parse_args(s)
end

"""
Generates a sample spin chain measurement from the wavefunction wf.
The idea is to simulate measuring
each site in sequence. After each measurement, the wavefunction is projected
onto the appropriate Hilbert subspace according to the Born rule.
"""
function measure(wf::AbstractArray)
  rng = MersenneTwister()
  Nsites = convert(Int64, log2(length(wf)))
  measurement = zeros(Nsites)

  shape = tuple(collect(repeated(2,Nsites))...)
  wf = reshape(wf, shape)
  for n = 1:Nsites
    println(wf)
    amp0 = sum(wf[1,..]) #this uses the EllipsisNotation package
    P0 = abs2(amp0)
    @assert P0>=1e-12 && P0<(1.0+1e-12) "P0 was $P0 which is not a probability"
    roll = rand(rng)
    if roll < P0
      outcome = 0
      wf = wf[1,..] / amp0 #this is the Born rule
    else
      outcome = 1
      amp1 = sum(wf[2,..])
      wf = wf[2,..] / amp1
    end
    measurement[n] = outcome
  end
  println(measurement)
  return measurement
end

"""
Generates N measurements from the wavefunction and saves them to disk.
The overwrite flag determines whether the output file is overwritten or
appended to.
"""
function savemeasurements(wavefunction::AbstractArray, 
                          outfilename::AbstractString, N::Int, overwrite::Bool)
  if overwrite
    mode = "w"
  else
    mode = "a"
  end
  open(outfilename, mode) do f
    for n = 1:N
      measurement = measure(wavefunction)
      writedlm(f, measurement)
    end
  end
end

function main()
  parsed_args = parse_commandline()
  println("Hi!! Generating field configurations from:")
  for (arg, val) in parsed_args
    println("   $arg    =>    $val")
  end
  infilename = parsed_args["infilename"]
  wavefunction = load(infilename, "wavefunction")
  outfilename = infilename[1:end-3]*string("out")
  savemeasurements(wavefunction, outfilename, parsed_args["N"], 
                   parsed_args["overwrite"])
  println("Done.")

end
main()