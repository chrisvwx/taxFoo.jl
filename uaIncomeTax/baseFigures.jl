using taxFoo
using Plots
using Taxsim
using DataFrames

function taxsim35rate(incomes,year,mstatus,cpiDict)
    if year<1960
        error("Taxsim only works for years >=1960")
    end
    map = [2 6 1 1];
    in = DataFrame(year=year, mstat=map[mstatus], pwages=incomes);
    out= taxsim35(in);
    return out.fiitax ./ incomes*100, (out.fiitax .+ out.fica) ./ incomes*100
end
#brackets,dedD,exeD,ssD,hiD,cpiDict = initTables();
tables = initTables();


using DelimitedFiles
uaUSCFile=string("./ua_ssUSC.csv")
uaUSC = readdlm(uaUSCFile,',')
uaDict = Dict(uaUSC[i,1]=>uaUSC[i,2:3] for i in 2:size(uaUSC)[1])

function uaTaxRate(income, uaDict,year)
    maxUSC = uaDict[year][1]
    rateUSC = uaDict[year][2]
    if income<maxUSC
        taxUSC = income*rateUSC
    else
        taxUSC = maxUSC*rateUSC
    end
    totalTax = taxUSC+ income*(.18 + .015)
    return totalTax/income
end
function uaTaxRate(incomes::Vector{Td},uaDict,year) where {Td<:Real}
    f(x) = uaTaxRate(x,uaDict, year)
    return f.(incomes)
end



#=   Make a figure showing US income tax from 1864 to 2024 in forty-year
     increments.
=#
function plotYear(plt,incomes,year,mstatus, labelTxt)
    incomeAdj = inflationCalc(incomes,2024,year,tables.cpiDict)
    if year<1960
        taxF = ficaRate(incomeAdj, tables, year, mstatus)
    else
        _,taxF = taxsim35rate(incomeAdj,year,mstatus,tables.cpiDict);
    end
    plot!(plt,incomes,taxF,label=string(year)*labelTxt,linewidth=2.5)
end
ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
xtickLabels = (10 .^collect(3:7), ["\$1k" "\$10k" "\$100k" "\$1M" "\$10M"])
plt = plot(xscale=:log10,legend_position=:topleft,
           xticks = xtickLabels,
           yticks = ytickLabels,
           legendfont =font(14),
           xtickfont =font(14),
           ytickfont =font(14),
           labelfontsize = 14,
           size=(1080,720),
           widen=true,
           xlabel="Incomes in 2024 dollars\n",
           ylabel="\nTax rate");
incomes = round.(10 .^collect(2.9:.1:7.1));
plotYear(plt,incomes,1918,1, " US WW1")
plotYear(plt,incomes,1945,1, " US WW2")
plotYear(plt,incomes,2023,1, " US")
uaRate = 100*uaTaxRate(incomes,uaDict,year)
plot!(plt,incomes,uaRate,label=string(year)*" Ukraine",linewidth=2.5)
annotate!(plt,7e2, -11,("c.im/@chrisp", 7,:grey,:center))
#annotate!(plt,8e3, -11,("github.com/chrisvwx/taxFoo.jl", 7,:grey,:center))
savefig("ukrVusaTax.png")


