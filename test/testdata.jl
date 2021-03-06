# data is generated by test/gendata.jl

# load test data
countsint = convert(Matrix{Int},CSV.read(joinpath(testdir,"data","countsint.csv.gz")))
covarsdf = CSV.read(joinpath(testdir,"data","covarsdf.csv.gz"))
categorical!(covarsdf, :cat)
counts = convert(SparseMatrixCSC{Float64,Int}, countsint)

# construct equivalent covars matrix so we can show how that api works too
covars = ModelMatrix(ModelFrame(@formula(y ~ x + z + cat + y), covarsdf)).m[:,2:end]

n, d = size(counts)
p = size(covars, 2)
ncats = length(levels(covarsdf.cat))

# used for testing predict
newcovars = covars[1:10,:]

# used for testing srproj and fit(CIR)
projdir = size(covars,2)

γdistrom = 1.0

coefsRdistrom = sparse(convert(Matrix{Float64},CSV.read(joinpath(testdir,"data","dmr_coefsRdistrom.csv.gz"))))
zRdistrom = convert(Matrix{Float64},CSV.read(joinpath(testdir,"data","dmr_zRdistrom.csv.gz")))
z1Rdistrom = convert(Matrix{Float64},CSV.read(joinpath(testdir,"data","dmr_z1Rdistrom.csv.gz")))
predictRdistrom = convert(Matrix{Float64},CSV.read(joinpath(testdir,"data","dmr_predictRdistrom.csv.gz")))
