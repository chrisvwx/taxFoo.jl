#=
To-do

* features to add
  - Documentation about Exemptions
      https://www.irs.gov/statistics/soi-tax-stats-historical-table-23
    for data in better format:
    https://www.taxpolicycenter.org/statistics/historical-individual-income-tax-parameters
     CSV version of this file is in src/exemptions.csv
  - Merge basefigs.jl, taxSimFigs.jl
  - put taxSim into animation on github after 1962
  - update taxFoo.jl on github
* plots
  - if we treat tax rates as a CDF, what's the PDF of incomes?

Future features
* EITC
* the "Maximum tax on earned income" (explains diff in 1980 at high incomes
  between taxFoo.jl and Taxsim)
      https://www.law.cornell.edu/cfr/text/26/1.1348-2
* medicare and social security
    https://www.milefoot.com/math/businessmath/taxes/fica.htm
* unemployment tax
* AMT?
* ? Medicare contribution tax
* Cap gains rates
  https://www.wolterskluwer.com/en/expert-insights/whole-ball-of-tax-historical-capital-gains-rates
  https://taxfoundation.org/data/all/federal/federal-capital-gains-tax-collections-historical-data/
  https://taxfoundation.org/data/all/federal/federal-capital-gains-tax-rates-1988-2013/
  https://en.wikipedia.org/wiki/Capital_gains_tax_in_the_United_States

Questions for Daniel F (Taxsim guy)
* What tax is causing effective tax to go above the highest bracket in 1968?
* Have you had any thoughts of adding things before 1960?
* What's the status of putting Taxsim on Github?

=#
module taxFoo

using DelimitedFiles

export
    initTables,
    firstYear, lastYear,
    incomeRate,taxRate,
    inflationCalc,inflationLevelBrackets,
    bracketsInPlotForm

"""
    bD,dD,ssD,hiD,cD = initTables()

Read income tax brackets, tax deduction, Social Security tax, Medicare tax,
and CPI data into dicts from default CSV files contained alongside the
source code. Tax bracket data comes from taxfoundation.org [1], tax
deduction data comes from [2][3], Social Security and Medicare data comes
from [4], and CPI data is from the Minneapolis Fed [4].

'initTables' is tuned to the specific CSV files shipped alongside this code,
and would need to be carefully tuned for other files. I.e. this function is
pretty fragile (like the rest of taxFoo? :-).

[1] https://taxfoundation.org/data/all/federal/historical-income-tax-rates-brackets/
[2] https://www.taxpolicycenter.org/sites/default/files/statistics/pdf/standard_deduction_2.pdf
[3] https://www.taxnotes.com/research/federal/reference-tables/standard-deduction/1x7yp
[4] https://www.taxpolicycenter.org/sites/default/files/statistics/pdf/ssrate_historical_2.pdf
[5] https://www.minneapolisfed.org/about-us/monetary-policy/inflation-calculator/consumer-price-index-1800-

# Examples
```jldoctest
julia> bD,dD,ssD,hiD,cD = initTables();

julia> tables.cD[1862]
30.0

```
"""
function initTables()
    bracketsFile= string(@__DIR__,"/brackets.csv")
    allBrackets = initBrackets(bracketsFile)
    
    deductionsFile=string(@__DIR__,"/deductions.csv")
    deds = readdlm(deductionsFile,',')
    dedDict = Dict(deds[i,1]=>deds[i,2:end] for i in 2:size(deds)[1])
    
    exemptionsFile=string(@__DIR__,"/exemptions.csv")
    exes = readdlm(exemptionsFile,',')
    exmpDict = Dict(exes[i,1]=>exes[i,2:end] for i in 4:size(exes)[1]-4)
    
    ssMedicareFile=string(@__DIR__,"/ssMedicare.csv")
    ssM = readdlm(ssMedicareFile,',')
    ssDict = Dict(ssM[i,1]=>ssM[i,2:3] for i in 2:size(ssM)[1])
    hiDict = Dict(ssM[i,1]=>ssM[i,4:5] for i in 2:size(ssM)[1])
    
    cpiFile=string(@__DIR__,"/cpi.csv")
    cpi = readdlm(cpiFile,',')
    cpiDict = Dict(cpi[i,1]=>cpi[i,2] for i in 1:size(cpi)[1])

    return allBrackets, dedDict, exmpDict, ssDict, hiDict, cpiDict
end


"""
    allBrackets = initBrackets(bracketsFile="src/brackets.csv")

Read income tax brackets from a file in the format of [1], convert them into 
per-marital-status matrices, and return the resulting dict. 

[1] https://taxfoundation.org/data/all/federal/historical-income-tax-rates-brackets/

# Examples
```jldoctest
julia> allBrackets = initBrackets();

julia> allBrackets[1862][1]
2×2 Matrix{Float64}:
 3.0    600.0
 5.0  10000.0

```
"""
function initBrackets(bracketsFile="src/brackets.csv")

    rawBrackets = readdlm(bracketsFile,',')

    ixInt = typeof.(rawBrackets[:,1]).==Int64
    firstYear = minimum(rawBrackets[ixInt,1])
    lastYear = maximum(rawBrackets[ixInt,1])
    Nyears = lastYear-firstYear+1

    # count bracket sizes
    bSizes = zeros(Int64, Nyears,5);
    Nrows = size(rawBrackets)[1]
    for rw = 2:Nrows
        year = rawBrackets[rw,1]
        if ~isempty(year) && isinteger(year)
            yx = year - firstYear+1
            bSizes[yx,1] = year
            for ix=0:3
                tmp = rawBrackets[rw,ix*3+2]
                if ~isempty(tmp) && ~(tmp.=="No income tax")
                    bSizes[yx,ix+2] +=1
                end
            end
        end
    end

    # parse brackets out of raw data
    allBrackets = Dict{Int64,Dict{Int64,Array{Float64,2}}}()
    thisIx = 0
    for rw = 2:Nrows
        year = rawBrackets[rw,1]
        if ~isempty(year) && isinteger(year)
            yx = year - firstYear+1
            if ~haskey(allBrackets,year)
                thisBracket = Dict{Int64,Array{Float64,2}}()
                push!(allBrackets,year=>thisBracket)
                for ix=0:3
                    Nbrackets = bSizes[yx,ix+2]
                    mat = fill(NaN,Nbrackets,2)
                    push!(thisBracket,ix+1=>mat)
                end
                thisIx=1
            else
                thisBracket = allBrackets[year]
                thisIx+=1
            end
            for ix=0:3
                tmp = rawBrackets[rw,ix*3+2]
                if ~isempty(tmp) && bSizes[yx,ix+2]>0
                    mat = thisBracket[ix+1]
                    mat[thisIx,1] = parse(Float64,tmp[1:end-1])
                    endBracket = replace(rawBrackets[rw,ix*3+4],","=>"")
                    endBracket = replace(endBracket,"\$"=>"")
                    mat[thisIx,2] = parse(Float64,endBracket)
                end
            end
        end
    end
    return allBrackets
end

firstYear(allBrackets) = minimum(keys(allBrackets))
lastYear(allBrackets) = maximum(keys(allBrackets))



"""
    r = incomeRate(income,bracket)

Return income tax rate given `income` and rates described `bracket`, which
should be a matrix where each row gives a tax bracket. The first column
of each row gives the rate for that tax bracket, while the second column
gives the income at which that bracket starts.  The rate is returned as a
percent; i.e. possibly ranging from 0 to 100%. 

# Examples
```jldoctest
julia> bracket = [ 3.0    600.0   # 1862 tax rate
                   5.0  10000.0]

julia> incomeRate(1000,bracket)
1.2

```
"""
function incomeRate(income::Real,bracket)
    if size(bracket)[1]==0
        return 0
    end
    diffb = diff(bracket[:,2])
    diffTx = diffb.* bracket[1:end-1,1]/100
    ix = findfirst(income.<bracket[:,2])
    if ~isnothing(ix)
        # income less than max bracket
        ~isinteger(ix) && ix<=0 && error("unknown error")
        if ix==1
            tax = 0
        else
            tax = sum(diffTx[1:ix-2])
            residualIncome = income-bracket[ix-1,2]
            tax += residualIncome*bracket[ix-1,1]/100
        end
    else
        # income greater than max bracket
        tax = sum(diffTx)
        residualIncome = income-bracket[end,2]
        tax += residualIncome*bracket[end,1]/100
    end
    return tax/income*100
end

incomeRate(income::Real,allBrackets,year::Integer,mstatus::Integer) = 
    incomeRate(income,allBrackets[year][mstatus])
function incomeRate(income::Vector{Td}, allBrackets, year::Integer,
                 mstatus::Integer)  where {Td<:Real}
    f(x) = incomeRate(x, allBrackets, year, mstatus)
    return f.(income)
end

function taxRate(income::Real,allBrackets, dedD, exeD, year, mstatus;
                 includeDeductions=true,includeExemptions=true)
    # if includeSS
    #     rateSS = .124
    #     taxSS = income*rateSS
    # end
    # if includeHI # Medicare
    #     rateHI = .029
    #     taxHI = income*rateHI
    # end

    incAfterDed = income
    if includeDeductions
        deduction = 0;
        if year >=1944 && year < 1970
            deduction = min(.1 * income,1000)
        elseif year>=1970
            deduction = dedD[year][mstatus]
        end
        incAfterDed = incAfterDed-deduction
    end
    if includeExemptions && year >=1913 && year < 2018
        mstatusMap = [2 2 1 1] # Needs confirming for HOH
        exemption = exeD[year][mstatusMap[mstatus]]
        incAfterDed = incAfterDed-exemption
    end
    rateIncome = incomeRate(incAfterDed,allBrackets,year,mstatus)
    taxIncome = rateIncome*incAfterDed/100
#    return (taxIncome+taxSS+taxHI)/income*100
    return taxIncome/income*100
end
function taxRate(incomes::Vector{Td},allBrackets, dedD, exeD, year,
                     mstatus) where {Td<:Real}
    f(x) = taxRate(x,allBrackets, dedD, exeD, year, mstatus)
    return f.(incomes)
end
function taxRate(income::Real,allBrackets, dedD, exeD, years::Vector{Td},
                     mstatus) where {Td<:Real}
    f(x) = taxRate(income,allBrackets, dedD, exeD, x, mstatus)
    return f.(years)
end

"""
    inflationCalc(price1,year1,year2,cpiDict)

Read cpi data into a dict indexed by year for use in inflation
calculations. By default CPI data from the Minneapolis Fed is used.

[1] https://www.minneapolisfed.org/about-us/monetary-policy/inflation-calculator/consumer-price-index-1800-

# Examples
```jldoctest
julia> cpiD = initCPI();

julia> round(inflationCalc(100,1862,2024,cpiD))
3128.0

```
"""
function inflationCalc(price1,year1,year2,cpiDict)
    # Year 2 Price = Year 1 Price x (Year 2 CPI/Year 1 CPI)
    return price1 * cpiDict[year2]/cpiDict[year1]
end
function inflationCalc(price1::Vector{Td},year1,year2,cpiDict)  where {Td<:Real}
    f(x) = inflationCalc(x, year1,year2,cpiDict)
    return f.(price1)
end


"""
    brackets=inflationLevelBrackets(allBrackets,cpiDict,targetYear)

Convert tax brackets in `allBrackets` into `targetYear` dollars.

# Examples
```jldoctest
julia> allBrackets = initBrackets();

julia> cpiD = initCPI();

julia> brackets=inflationLevelBrackets(allBrackets,cpiD,2024)

julia> allBrackets[1862][1]
2×2 Matrix{Float64}:
 3.0    600.0
 5.0  10000.0

julia> round.(brackets[1862][1])  # 1864 brackets in 2024 dollars
2×2 Matrix{Float64}:
 3.0   18770.0
 5.0  312833.0

```
"""
function inflationLevelBrackets(allBrackets,cpiDict,targetYear)
    leveledBrackets = deepcopy(allBrackets)
    firstYear = Integer(minimum(keys(allBrackets)))
    lastYear = Integer(maximum(keys(allBrackets)))
    for year = firstYear:lastYear
        levelCalc(price) = inflationCalc(price,year,targetYear,cpiDict)
        for i = 1:4
            leveledBrackets[year][i][:,2] = levelCalc.(allBrackets[year][i][:,2])
        end
    end
    return leveledBrackets
end


"""
    incomes,rate = bracketsInPlotForm(bracket)

Return an income, rate pair in a form that can easily be plotted.

# Examples
```jldoctest
julia> bracket = [ 3.0    600.0   # 1862 tax rate
                   5.0  10000.0]

julia> out = bracketsInPlotForm(bracket)
8×2 Matrix{Float64}:
     1.0      0.0
   600.0      0.0
   600.5    NaN
   601.0      3.0
 10000.0      3.0
 10000.5    NaN
 10001.0      5.0
     1.0e7    5.0

```
"""
function bracketsInPlotForm(bracket)
    Nbrackets = size(bracket)[1]
    if ~isapprox(bracket[1,2],0)
        Nbrackets+=1
    end
    out = zeros(Float64,Nbrackets*3-1,2)
    bx = 1 # index into bracket
    ox = 3 # index into out 
    if isapprox(bracket[1,2],0)
        out[1,1] = 1
        out[1,2] = bracket[1,1]
        out[2,1] = bracket[2,2]
        out[2,2] = bracket[1,1]
        bx += 1
    else
        out[1,:] = [1 0]
        out[2,1] = bracket[1,2]
        out[2,2] = 0
    end
    while bx <= size(bracket)[1]
        out[ox,  1] = bracket[bx,2]+.5
        out[ox,  2] = NaN
        out[ox+1,1] = bracket[bx,2]+1
        out[ox+1,2] = bracket[bx,1]
        if bx< size(bracket)[1]
            out[ox+2,1] = bracket[bx+1,2]
        else
            out[ox+2,1] = 1e8
        end
        out[ox+2,2] = bracket[bx,1]
        bx += 1
        ox+=3
    end
    return out
end

bracketsInPlotForm(allBrackets,year::Integer,mstatus::Integer) =
    bracketsInPlotForm(allBrackets[year][mstatus])



end # module taxFoo

