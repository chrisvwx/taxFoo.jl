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
# leveledBrackets is for plots of statutory brackets in 2024 dollars
leveledBrackets=inflationLevelBrackets(tables.brackets,tables.cpiDict,2024);




#=   show brackets, effective income tax, and taxsim; all w/o FICA
=#
year = 2023
mstatus = 1;
incomes = round.(10 .^collect(3.5:.005:7.1));
tax = incomeRate(incomes, tables.brackets, year, mstatus);
taxD = taxRate(incomes, tables, year, mstatus);
pltTx = bracketsInPlotForm(tables.brackets, year, mstatus);

map = [2 6 1 1];
in = DataFrame(year=year, mstat=map[mstatus], pwages=incomes);
out= taxsim35(in);
taxsimrate = out.fiitax ./ incomes*100;

ytickLabels=([0; 10;12;22;24;32;35;37;41],
             ["0%" "10%" "12%" "22%" "24%" "32%" "35%" "37%"])
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
           xlabel="Incomes in "*string(year)*" dollars (log axis)\n",
           ylabel="\nTax rate");
plot!(plt,pltTx[:,1],pltTx[:,2],label=string(year)*" brackets",linewidth=2.5)
plot!(plt,incomes,tax,label=string(year)*" tax w/o deduction from taxFoo.jl",linewidth=2.5)
plot!(plt,incomes,taxD,label=string(year)*" tax w deduction from taxFoo.jl",linewidth=2.5)
plot!(plt,incomes,taxsimrate,label=string(year)*" Taxsim w/o FICA",linewidth=2.5)
#annotate!(plt,7e3, 7,("c.im/@chrisp", 7,:grey,:center))
savefig(string(year)*"bracketsAndTaxsim.png")





#=   show effective income tax and taxsim; all with FICA
=#
year = 1960;
mstatus = 1;
incomes = round.(10 .^collect(2.9:.1:6.3));
taxD = taxRate(incomes, tables, year, mstatus);
taxF = ficaRate(incomes, tables, year, mstatus);

map = [2 6 1 1];
in = DataFrame(year=year, mstat=map[mstatus], pwages=incomes);
out= taxsim35(in);
taxsimrate = out.fiitax ./ incomes*100;
taxsimFICA = (out.fiitax + out.fica) ./ incomes*100;

ytickLabels=([-10; 0; 10; 20; 30; 40;],
             ["-10%" "0%" "10%" "20%" "30%" "40%"])
ytickLabels=([0; 10; 20; 30; 40; 50; 60; 70; 80; 90],
             ["0%" "10%" "20%" "30%" "40%" "50%" "60%" "70%" "80%" "90%"])
xtickLabels = (10 .^collect(4:7), ["\$10k" "\$100k" "\$1M" "\$10M"])
xtickLabels = (10 .^collect(3:6), ["\$1k" "\$10k" "\$100k" "\$1M"])
plt = plot(xscale=:log10,legend_position=:bottomright,
           yticks = ytickLabels,
           xticks = xtickLabels,
           legendfont =font(14),
           xtickfont =font(14),
           ytickfont =font(14),
           labelfontsize = 14,
           xlims=(1e3,1e6),
           size=(1080,720),
           widen=true,
           xlabel="Incomes in "*string(year)*" dollars (log axis)\n",
           ylabel="\nTax rate");
plot!(plt,incomes,taxD,label=string(year)*" taxFoo.jl w/o FICA",linewidth=2.5)
plot!(plt,incomes,taxF,label=string(year)*" taxFoo.jl with FICA",linewidth=2.5)
plot!(plt,incomes,taxsimrate,label=string(year)*" Taxsim w/o FICA",
      linewidth=0,marker = (:square, 5, 0.5))
plot!(plt,incomes,taxsimFICA,label=string(year)*" Taxsim with FICA",
      linewidth=0,marker = (:circle, 5, 0.5))
#annotate!(plt,7e3, 7,("c.im/@chrisp", 7,:grey,:center))
savefig(string(year)*"bracketsAndTaxsimFICA.png")



#=   show brackets and effective income tax
=#
year = 1978;
mstatus = 1;
incomes = round.(10 .^collect(3.5:.01:7.1));
tax = incomeRate(incomes, tables.brackets, year, mstatus);
taxD = taxRate(incomes, tables, year, mstatus);
pltTx = bracketsInPlotForm(tables.brackets, year, mstatus);
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
           xlims=(5e3,5e6),
           widen=true,
           xlabel="Incomes in "*string(year)*" dollars (log axis)\n",
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
tax1 = taxRate(incomes, tables, year, 1)
tax2 = taxRate(incomes, tables, year, 2)
tax3 = taxRate(incomes, tables, year, 3)
tax4 = taxRate(incomes, tables, year, 4)
#plt = plot(xscale=:log10,legend_position=false);
plt = plot(xscale=:log10);
plot!(plt,incomes,tax1,linecolor=:blue,label="MfJ")
plot!(plt,incomes,tax2,linecolor=:red,label="MfS")
plot!(plt,incomes,tax3,linecolor=:green,label="Single")
plot!(plt,incomes,tax4,linecolor=:black,label="HoH")





#=   Animated GIF: income tax w/o FICA
=#
function plotYearAnim(year,mstatus,incomes)
    incomeAdj = inflationCalc(incomes,2024,year,tables.cpiDict)
    # tax1 = incomeRate(incomeAdj, brackets, year, mstatus);
    taxD = taxRate(incomeAdj, tables, year, mstatus);
    # if year>=1944
    #     taxD = taxRate(incomeAdj, tables, year, mstatus);
    # end
    if size(leveledBrackets[year][mstatus])[1]>0
        pltTx = bracketsInPlotForm(leveledBrackets, year, mstatus);
    end

    plt = plot(xscale=:log10,legend_position=:topleft,
               xticks = xtickLabels,
               yticks = ytickLabels,
               xtickfont =font(14),
               ytickfont =font(14),
               legendfont =font(14),
               labelfontsize = 14,
               size=(1080,720),
               widen=true,
               xlims=(4e3,4e7),
               ylims=(-15,90),
               xlabel="Wage income in 2024 dollars\n",
               ylabel="\nTax rate");
    if size(leveledBrackets[year][mstatus])[1]>0
        # plot!(plt,pltTx[:,1],pltTx[:,2],label=string(year)*" brackets",
        #       linewidth=2.5,linecolor=:blue)
        plot!(plt,pltTx[:,1],pltTx[:,2],label="base brackets",
              linewidth=2.5,linecolor=:blue)
    end
    plot!(plt,incomes,taxD, linewidth=2.5,label="taxFoo.jl")
    # if year>=1944
    #     plot!(plt,incomes,tax1, linewidth=2.5,label=" w/o deduction",linecolor=:red)
    #     plot!(plt,incomes,taxD, linewidth=2.5,label=" w/ std deduction",
    #           linecolor=:green)
    # else
    #     plot!(plt,incomes,tax1, linewidth=2.5,label=" effective tax",linecolor=:red)
    # end
    if year>=1960
        taxsimR,taxsimFICA = taxsim35rate(incomeAdj,year,mstatus,tables.cpiDict);
        plot!(plt,incomes,taxsimR, linewidth=2.5,label="Taxsim w/o FICA")
        plot!(plt,incomes,taxsimFICA, linewidth=2.5,label="Taxsim with FICA")
    end
    
    annotate!(plt,15000, 60, string(year), font(48))
end
mstatus=1
incomes = round.(10 .^collect(3.4:.1:7.4));
xtickLabels = (10 .^collect(4:7), ["\$10k" "\$100k" "\$1M" "\$10M"])
ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
yearBeg = firstYear(tables.brackets)
yearBeg = 1960
yearEnd = lastYear(tables.brackets)
yearEnd = 2080
anim = Animation()
for year=yearBeg:4:yearEnd
    display(year)
    plotYearAnim(year,mstatus,incomes)
    frame(anim)
end
plot(legend=false,grid=false,foreground_color_subplot=:white,size=(1080,720))  
frame(anim)
frame(anim)
frame(anim)
gif(anim, "animatedBrackets.gif", fps = 5)



#=   Animated GIF: income tax with FICA
=#
function plotYearTotal(year,mstatus,incomes)
    incomeAdj = inflationCalc(incomes,2024,year,tables.cpiDict)
    # tax1 = incomeRate(incomeAdj, brackets, year, mstatus);
    taxD =  taxRate(incomeAdj, tables, year, mstatus);
    taxF = ficaRate(incomeAdj, tables, year, mstatus);
    if size(leveledBrackets[year][mstatus])[1]>0
        pltTx = bracketsInPlotForm(leveledBrackets, year, mstatus);
    end

    plt = plot(xscale=:log10,legend_position=:topleft,
               xticks = xtickLabels,
               yticks = ytickLabels,
               xtickfont =font(14),
               ytickfont =font(14),
               legendfont =font(14),
               labelfontsize = 14,
               size=(1080,720),
               widen=true,
               xlims=(4e3,4e7),
               ylims=(-15,90),
               xlabel="Wage income in 2024 dollars\n",
               ylabel="\nTax rate");
    if size(leveledBrackets[year][mstatus])[1]>0
        plot!(plt,pltTx[:,1],pltTx[:,2],label="base brackets",
              linewidth=2.5,linecolor=:blue)
    end
    if year<1960
        plot!(plt,incomes,taxD, linewidth=2.5,label="taxFoo.jl")
        if year>=1937
            plot!(plt,incomes,taxF, linewidth=2.5,label="taxFoo.jl with FICA")
        end
    end
    if year>=1960
        taxsimR,taxsimFICA = taxsim35rate(incomeAdj,year,mstatus,tables.cpiDict);
        plot!(plt,incomes,taxsimR, linewidth=2.5,label="Taxsim")
        plot!(plt,incomes,taxsimFICA, linewidth=2.5,label="Taxsim with FICA")
    end
    
    annotate!(plt,15000, 60, string(year), font(48))
end
mstatus=1
incomes = round.(10 .^collect(3.4:.1:7.5));
xtickLabels = (10 .^collect(4:7), ["\$10k" "\$100k" "\$1M" "\$10M"])
ytickLabels = (collect(0:20:80), ["0%" "20%" "40%" "60%" "80%"])
yearBeg = firstYear(tables.brackets)
#yearBeg = 1940
yearEnd = lastYear(tables.brackets)
yearEnd = 2023
anim = Animation()
for year=yearBeg:yearEnd
    display(year)
    plotYearTotal(year,mstatus,incomes)
    frame(anim)
end
plot(legend=false,grid=false,foreground_color_subplot=:white,size=(1080,720))  
frame(anim)
frame(anim)
frame(anim)
gif(anim, "animatedTotal.gif", fps = 5)




#=   Make a figure showing US income tax from 1864 to 2024 in forty-year
     increments.
=#
function plotYear(plt,incomes,year,mstatus)
    incomeAdj = inflationCalc(incomes,2024,year,tables.cpiDict)
    tax1 = taxRate(incomeAdj, tables, year, mstatus)
    plot!(plt,incomes,tax1,label=string(year),linewidth=2.5)
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



#=
Functions to export tax data to CSV files for use elsewhere. The data in
SRW's blog post[1] comes from these files.

[1] https://drafts.interfluidity.com/2024/06/03/the-us-federal-income-tax-in-pictures
=#

function getRate(year,mstatus,incomes)
    rate1(income) = taxRate(income,tables, year,mstatus)
    return rate1.(incomes)
end
incomes = round.(10 .^collect(3:.1:8));
Nincomes = length(incomes)
statusStrs = ["mfj", "mfs", "single", "hoh"]
yearBeg = firstYear(tables.brackets)
yearEnd = lastYear(tables.brackets)

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

