
using taxFoo
using Plots
using Taxsim
using DataFrames

allBrackets,deductionsD,cpiDict = initTables();
brackets = inflationLevelBrackets(allBrackets,cpiDict,2024);
dedD = inflationLevelDeductions(deductionsD,cpiDict,2024);

#=   show brackets and effective income tax
=#
year = 2023;
mstatus = 1;
incomes = round.(10 .^collect(3.4:.005:7.1));
tax = incomeRate(incomes, allBrackets, year, mstatus);
taxD = rateWithDed(incomes, allBrackets, deductionsD, year, mstatus);
pltTx = bracketsInPlotForm(allBrackets, year, mstatus);

map = [2 6 1 1];
#incPast = inflationCalc(incomes,2024,year,cpiDict);
incPast = incomes;
in = DataFrame(year=year, mstat=map[mstatus], pwages=incPast);
out= taxsim32(in);
taxsimrate = out.fiitax ./ incPast*100;


ytickLabels=([0; 10;12;22;24;32;35;37], ["0%" "10%" "12%" "22%" "24%" "32%" "35%" "37%"])
xtickLabels = (10 .^collect(4:7), ["\$10k" "\$100k" "\$1M" "\$10M"])
plt = plot(xscale=:log10,legend_position=:bottomright,
           xticks = xtickLabels,
           yticks = ytickLabels,
           legendfont =font(14),
           xtickfont =font(14),
           ytickfont =font(14),
           labelfontsize = 14,
           size=(1080,720),
           xlims=(4e3,1e7),
           widen=true,
           xlabel="Income (log axis)\n",
           ylabel="\nTax rate");
plot!(plt,pltTx[:,1],pltTx[:,2],label=string(year)*" brackets",linewidth=2.5)
plot!(plt,incomes,tax,label=string(year)*" effective tax w/o deduction",linewidth=2.5)
plot!(plt,incomes,taxD,label=string(year)*" effective tax with deduction",linewidth=2.5)
plot!(plt,incomes,taxsimrate,label=string(year)*" rate from Taxsim",linewidth=2.5)
#annotate!(plt,7e3, 7,("c.im/@chrisp", 7,:grey,:center))
savefig("2023bracketsAndTaxsim.png")



#=   show brackets and effective income tax
=#
year = 1970;
mstatus = 1;
incomes = round.(10 .^collect(3.5:.01:7.1));
tax = incomeRate(incomes, brackets, year, mstatus);
taxD = rateWithDed(incomes, brackets, dedD, year, mstatus);
pltTx = bracketsInPlotForm(brackets, year, mstatus);
ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
xtickLabels = (10 .^collect(4:7), ["\$10k" "\$100k" "\$1M" "\$10M"])
plt = plot(xscale=:log10,legend_position=:topleft,
           xticks = xtickLabels,
           yticks = ytickLabels,
           legendfont =font(14),
           xtickfont =font(14),
           ytickfont =font(14),
           labelfontsize = 14,
           size=(1080,720),
           xlims=(5e3,1e7),
           widen=true,
           xlabel="Incomes in 2024 dollars (log axis)\n",
           ylabel="\nTax rate");
plot!(plt,pltTx[:,1],pltTx[:,2],label=string(year)*" brackets",linewidth=2.5)
plot!(plt,incomes,tax,label=string(year)*" effective tax w/o deduction",linewidth=2.5)
plot!(plt,incomes,taxD,label=string(year)*" effective tax with deduction",linewidth=2.5)
#annotate!(plt,7e3, 7,("c.im/@chrisp", 7,:grey,:center))




#=   Comparing tax rates for different marital statuses. This
     figure isn't especially interesting and isn't polished  
=#
year = 2024
incomes = round.(10 .^collect(3.5:.1:7.5));
tax1 = rateWithDed(incomes, brackets, dedD, year, 1)
tax2 = rateWithDed(incomes, brackets, dedD, year, 2)
tax3 = rateWithDed(incomes, brackets, dedD, year, 3)
tax4 = rateWithDed(incomes, brackets, dedD, year, 4)
#plt = plot(xscale=:log10,legend_position=false);
plt = plot(xscale=:log10);
plot!(plt,incomes,tax1,linecolor=:blue,label="MfJ")
plot!(plt,incomes,tax2,linecolor=:red,label="MfS")
plot!(plt,incomes,tax3,linecolor=:green,label="Single")
plot!(plt,incomes,tax4,linecolor=:black,label="HoH")




#=   Animated GIF showing US income tax rates from 1862 to 2024
=#
function plotYearAnim(year,mstatus)
    tax1 = incomeRate(incomes, brackets, year, mstatus);
    if year>=1944
        taxD = rateWithDed(incomes, brackets, dedD, year, mstatus);
    end
    if size(brackets[year][mstatus])[1]>0
        pltTx = bracketsInPlotForm(brackets, year, mstatus);
    end

    plt = plot(xscale=:log10,legend_position=:topright,
               xticks = xtickLabels,
               yticks = ytickLabels,
               xtickfont =font(14),
               ytickfont =font(14),
               legendfont =font(14),
               labelfontsize = 14,
               size=(1080,720),
               widen=true,
               xlims=(9e3,1e7),
               ylims=(0,90),
               xlabel="Incomes in 2024 dollars\n",
               ylabel="\nTax rate");
    if size(brackets[year][mstatus])[1]>0
        plot!(plt,pltTx[:,1],pltTx[:,2],label=string(year)*" brackets",
              linewidth=2.5,linecolor=:blue)
    end
    if year>=1944
        plot!(plt,incomes,tax1, linewidth=2.5,label=" w/o deduction",linecolor=:red)
        plot!(plt,incomes,taxD, linewidth=2.5,label=" w/ std deduction",
              linecolor=:green)
    else
        plot!(plt,incomes,tax1, linewidth=2.5,label=" effective tax",linecolor=:red)
    end
    annotate!(plt,4e4, 80, string(year), font(48))
end
incomes = round.(10 .^collect(3.9:.1:7.1));
xtickLabels = (10 .^collect(3:7), ["\$1k" "\$10k" "\$100k" "\$1M" "\$10M"])
ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
yearBeg = firstYear(brackets)
yearEnd = lastYear(brackets)
anim = Animation()
for year=yearBeg:yearEnd
    plotYearAnim(year,1)
    frame(anim)
end
plot(legend=false,grid=false,foreground_color_subplot=:white,size=(1080,720))  
frame(anim)
frame(anim)
frame(anim)
gif(anim, "animatedBrackets.gif", fps = 6)



#=   Make a figure showing US income tax from 1864 to 2024 in forty-year
     increments.
=#
function plotYear(plt,incomes,year,mstatus)
    tax1 = rateWithDed(incomes, brackets, dedD, year, mstatus)
    plot!(plt,incomes,tax1,label=string(year)*" effective",linewidth=2.5)
end
ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
xtickLabels = (10 .^collect(4:7), ["\$10k" "\$100k" "\$1M" "\$10M"])
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
incomes = round.(10 .^collect(3.9:.1:7.1));
plotYear(plt,incomes,1864,1)
plotYear(plt,incomes,1904,1)
plotYear(plt,incomes,1944,1)
plotYear(plt,incomes,1984,1)
plotYear(plt,incomes,2024,1)
annotate!(plt,7e3, -11,("c.im/@chrisp", 7,:grey,:center))
#annotate!(plt,8e3, -11,("github.com/chrisvwx/taxFoo.jl", 7,:grey,:center))
savefig("fortyYearIncrements.png")



# bSizes  is not exported from taxFoo at present.

# plot(bSizes[:,1],bSizes[:,2],
#      legend_position=false,
#      xtickfont =font(12),
#      ytickfont =font(12),
#      titlefont =font(12),
#      xlabel="\nYear",
#      title="Number of income tax brackets\n")




function getRate(year,mstatus,incomes)
    rate1(income) = rateWithDed(income,brackets, dedD, year,mstatus)
    return rate1.(incomes)
end
incomes = round.(10 .^collect(3:.1:8));
Nincomes = length(incomes)
statusStrs = ["mfj", "mfs", "single", "hoh"]
yearBeg = firstYear(brackets)
yearEnd = lastYear(brackets)

for status = 1:4
    io = open(statusStrs[status]*".csv","w")
    print(io,"Incomes")
    for i=1:Nincomes
        thisIncome = Int64(round(incomes[i]))
        print(io,", $thisIncome")
    end
    println(io,"")
    for year=yearBeg:yearEnd
        rates = getRate(year,status,incomes)
        print(io,"$year")
        for i=1:Nincomes
            thisrate = round(rates[i]*100)/100
            print(io,", $thisrate")
        end
        println(io,"")
    end
    close(io)
end

