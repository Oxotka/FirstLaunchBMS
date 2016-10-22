Function PredifenedDateAtServer(Postfix) Export
	
	Structure = New Structure;
	Postfix   = Upper(Postfix);
	
	PredifenedDateAtServerForCountry(Structure, Postfix);
	
	Return Structure;
	
EndFunction

Procedure CreateCompany(Structure) Export
	
	// Fill petty cashes.
	NameOfPettyCash = Structure.Company.NameOfPettyCash;
	PettyCash = Catalogs.TaxTypes.FindByDescription(NameOfPettyCash);
	If Not ValueIsFilled(PettyCash) Then
		PettyCash = Catalogs.PettyCashes.CreateItem();
		PettyCash.Description       = NameOfPettyCash;
		PettyCash.CurrencyByDefault = Structure.AccountingCurrency;
		PettyCash.GLAccount         = ChartsOfAccounts.Managerial.PettyCash;
		PettyCash.Write();
	EndIf;
	
	// Fill in companies.
	OurCompanyRef = Catalogs.Companies.MainCompany;
	OurCompany = OurCompanyRef.GetObject();
	FillPropertyValues(OurCompany, Structure.Company);
	OurCompany.Description                   = OurCompany.DescriptionFull;
	OurCompany.PayerDescriptionOnTaxTransfer = OurCompany.DescriptionFull;
	OurCompany.PettyCashByDefault            = PettyCash.Ref;
	OurCompany.BusinessCalendar              = SmallBusinessServer.GetCalendarByProductionCalendaRF();
	OurCompany.Write();
	
	// Fill in prices kinds.
	// Wholesale.
	WholesaleRef = Catalogs.PriceKinds.Wholesale;
	Wholesale = WholesaleRef.GetObject();
	Wholesale.PriceCurrency = Structure.NationalCurrency;
	Wholesale.PriceIncludesVAT = True;
	Wholesale.RoundingOrder = Enums.RoundingMethods.Round1;
	Wholesale.RoundUp = False;
	Wholesale.PriceFormat = "ND=15; NFD=2";
	Wholesale.Write();
	
	// Accountable.
	AccountingReference = Catalogs.PriceKinds.Accounting;
	Accounting = AccountingReference.GetObject();
	Accounting.PriceCurrency = Structure.AccountingCurrency;
	Accounting.PriceIncludesVAT = True;
	Accounting.RoundingOrder = Enums.RoundingMethods.Round1;
	Accounting.RoundUp = False;
	Accounting.PriceFormat = "ND=15; NFD=2";
	Accounting.Write();
	
EndProcedure

#Region MainProcedures

Procedure PredifenedDateAtServerForCountry(Structure, Postfix)
	
	// 1. Fill tax types
	FillTaxTypes(Postfix);
	// 2. Currency
	FillCurrency(Structure, Postfix);
	// 3. Fill in VAT rates.
	FillVATRates(Structure, Postfix);
	// 4. Fill in classifier of the working time use.
	FillClassifierOfWorkingTimeUsage(Postfix);
	// 5. Fill description of company.
	FillInformationAboutNewCompany(Structure, Postfix);
	
EndProcedure

Procedure FillTaxTypes(Postfix)
	
	If ThisIsRu(Postfix) Then 
		FillTaxTypesRu();
	// ElsIf ThisIsRo(Postfix) Then
	Else
		FillTaxTypesDefault();
	EndIf
	
EndProcedure

Procedure FillCurrency(Structure, Postfix)
	
	If ThisIsRu(Postfix) Then 
		FillCurrencyRu(Structure);
	Else
		FillCurrencyDefault(Structure);
	EndIf
	

EndProcedure

Procedure FillVATRates(Structure, Postfix)
	
	If ThisIsRu(Postfix) Then 
		FillVATRatesRu(Structure);
	Else
		FillVATRatesDefault(Structure);
	EndIf
	
EndProcedure

Procedure FillClassifierOfWorkingTimeUsage(Postfix)
	
	If ThisIsRu(Postfix) Then 
		FillClassifierOfWorkingTimeUsageRu();
	Else
		FillClassifierOfWorkingTimeUsageDefault();
	EndIf
	
EndProcedure

Procedure FillInformationAboutNewCompany(Structure, Postfix)
	
	If ThisIsRu(Postfix) Then 
		FillInformationAboutNewCompanyRu(Structure);
	Else
		FillInformationAboutNewCompanyDefault(Structure);
	EndIf
	
EndProcedure

#EndRegion

#Region ProceduresForCountry

#Region Default

// 1.
Procedure FillTaxTypesDefault()
	
	If ValueIsFilled(Catalogs.TaxTypes.FindByDescription("VAT")) Then
		Return;
	EndIf;
	
	// 1. VAT.
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "VAT";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();

	// 2. Profit Tax.
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Income tax";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
EndProcedure

// 2.
Procedure FillCurrencyDefault(Structure)
	
	// 4. Fill in currencies.
	CurrencyRef = InfobaseUpdateSB.FindCreateCurrency("643", "rub.", "Russian ruble", "ruble, ruble, rubles, M, kopek, kopek, kopeks, F, 2");  // TODO Change for EUR
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	// If it necessary to keep accounts of operations in several currencies, you should enable this option
	Constants.FunctionalCurrencyTransactionsAccounting.Set(False);
	
	Structure.Insert("Currency", CurrencyRef);
	
EndProcedure

// 3.
Procedure FillVATRatesDefault(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("18%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	// 10%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "10%";
	VATRate.Rate = 10;
	VATRate.Write();
	
	// 18% / 118%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "18% / 118%";
	VATRate.Calculated = True;
	VATRate.Rate = 18;
	VATRate.Write();
	
	// 10% / 110%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "10% / 110%";
	VATRate.Calculated = True;
	VATRate.Rate = 10;
	VATRate.Write();
	
	// 0%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "0%";
	VATRate.Rate = 0;
	VATRate.Write();
	
	// Without VAT
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "Without VAT";
	VATRate.NotTaxable = True;
	VATRate.Rate = 0;
	VATRate.Write(); 
	
	// 18%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "18%";
	VATRate.Rate = 18;
	VATRate.Write();
	
	Structure.Insert("VAT", VATRate.Ref);
	
EndProcedure

// 4. 
Procedure FillClassifierOfWorkingTimeUsageDefault()
	
	// B.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Disease;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Temporary incapacity to labor with benefit assignment according to the law";
	WorkingHoursKinds.Write();
	
	// V.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WeekEnd;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Weekends (weekly leave) and public holidays";
	WorkingHoursKinds.Write();
	
	// VP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Dead time by the employees fault";
	WorkingHoursKinds.Write();
	
	// VCH.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WorkEveningClock;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Working hours in the evenings";
	WorkingHoursKinds.Write();
	
	// G.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.PublicResponsibilities;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Absenteeism at the time of state or public duties according to the law";
	WorkingHoursKinds.Write();
	
	// DB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Annual additional leave without salary";
	WorkingHoursKinds.Write();
	
	// TO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Leave without pay provided to employee with employer permission";
	WorkingHoursKinds.Write();
	
	// ZB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Strike;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Strike (in conditions and order provided by legislation)";
	WorkingHoursKinds.Write();
	
	// TO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.BusinessTrip;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Business trip";
	WorkingHoursKinds.Write();
	
	// N.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WorkNightHours;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Working hours at night time";
	WorkingHoursKinds.Write();
	
	// NB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Suspension from work (disqualification) as required by the Law, without payroll";
	WorkingHoursKinds.Write();
	
	// NV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Additional days off (without salary)";
	WorkingHoursKinds.Write();
	
	// NZ.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.SalaryPayoffDelay;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Suspension of work in case of delayed salary";
	WorkingHoursKinds.Write();
	
	// NN.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Unjustified absence from work (until the circumstances are clarified)";
	WorkingHoursKinds.Write();
	
	// NO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Suspension from work (disqualification) with payment (benefit) according to the law";
	WorkingHoursKinds.Write();
	
	// NP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Simple;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Downtime due to reasons regardless of the employer and the employee";
	WorkingHoursKinds.Write();
	
	// OV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Additional days-off (paid)";
	WorkingHoursKinds.Write();
	
	// OD.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalVacation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Annual additional paid leave";
	WorkingHoursKinds.Write();
	
	// OZH.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationByCareForBaby;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Maternity leave up to the age of three";
	WorkingHoursKinds.Write();
	
	// OZ.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Leave without pay in cases provided by law";
	WorkingHoursKinds.Write();
	
	// OT.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.MainVacation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Annual paid leave";
	WorkingHoursKinds.Write();
	
	// PV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.ForcedTruancy;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Time of the forced absenteeism in case of the dismissal recognition, transition to another work place or dismissal from work with reemployment on the former one";
	WorkingHoursKinds.Write();
	
	// PK.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.QualificationRaise;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "On-the-job further training";
	WorkingHoursKinds.Write();
	
	// PM.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Further training off-the-job in other area";
	WorkingHoursKinds.Write();
	
	// PR.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Truancies;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Absenteeism (absence from work place without valid reasons within the time fixed by the law)";
	WorkingHoursKinds.Write();
	
	// R.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Maternity leave (vacation because of newborn baby adoption)";
	WorkingHoursKinds.Write();
	
	// RV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Holidays;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Working hours at weekends and non-work days, holidays";
	WorkingHoursKinds.Write();
	
	// RP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DowntimeByEmployerFault;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Dead time by employers fault";
	WorkingHoursKinds.Write();
	
	// C.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Overtime;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Overtime duration";
	WorkingHoursKinds.Write();
	
	// T.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DiseaseWithoutPay;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Temporary incapacity to labor without benefit assignment in cases provided by the law";
	WorkingHoursKinds.Write();
	
	// Y.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationForTraining;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Additional leave due to training with an average pay, combining work and training";
	WorkingHoursKinds.Write();
	
	// YD.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Additional leave because of the training without salary";
	WorkingHoursKinds.Write();
	
	// I.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Work;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Working hours in the daytime";
	WorkingHoursKinds.Write();
	
EndProcedure

// 5.
Procedure FillInformationAboutNewCompanyDefault(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull",       "LLC ""Our company""");
	StructureCompany.Insert("Prefix",                "OF-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice",     True);
	StructureCompany.Insert("NameOfPettyCash",       "Main petty cash");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure

#EndRegion

#Region Ru

// 1.
Procedure FillTaxTypesRu()
	
	If ValueIsFilled(Catalogs.TaxTypes.FindByDescription("НДС")) Then
		Return;
	EndIf;
	
	// 1. VAT.
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "НДС";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();

	// 2. Profit Tax.
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Налог на прибыль";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
EndProcedure

// 2.
Procedure FillCurrencyRu(Structure)
	
	CurrencyRef = InfobaseUpdateSB.FindCreateCurrency("643", "руб.", "Российский рубль", "рубль, рубля, рублей, M, копейка, копейки, копеек, F, 2");
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	// If it necessary to keep accounts of operations in several currencies, you should enable this option
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	Structure.Insert("Currency", CurrencyRef);
	
EndProcedure

// 3.
Procedure FillVATRatesRu(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("18%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	// 10%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "10%";
	VATRate.Rate = 10;
	VATRate.Write();
	
	// 18% / 118%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "18% / 118%";
	VATRate.Calculated = True;
	VATRate.Rate = 18;
	VATRate.Write();
	
	// 10% / 110%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "10% / 110%";
	VATRate.Calculated = True;
	VATRate.Rate = 10;
	VATRate.Write();
	
	// 0%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "0%";
	VATRate.Rate = 0;
	VATRate.Write();
	
	// Без НДС
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "Без НДС";
	VATRate.NotTaxable = True;
	VATRate.Rate = 0;
	VATRate.Write(); 
	
	// 18%
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "18%";
	VATRate.Rate = 18;
	VATRate.Write();
	
	Structure.Insert("VAT", VATRate.Ref);
	
EndProcedure

// 4. 
Procedure FillClassifierOfWorkingTimeUsageRu()
	
	// B.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Disease;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Временная нетрудоспособность с назначением пособия согласно законодательству";
	WorkingHoursKinds.Write();
	
	// V.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WeekEnd;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Выходные дни (еженедельный отпуск) и  нерабочие праздничные дни";
	WorkingHoursKinds.Write();
	
	// VP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Простои по вине работника";
	WorkingHoursKinds.Write();
	
	// VCH.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WorkEveningClock;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Продолжительность работы в вечернее время";
	WorkingHoursKinds.Write();
	
	// G.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.PublicResponsibilities;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Невыходы на время исполнения государственных или общественных обязанностей согласно законодательству";
	WorkingHoursKinds.Write();
	
	// DB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Ежегодный дополнительный отпуск без сохранения заработной платы";
	WorkingHoursKinds.Write();
	
	// TO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Отпуск без сохранения заработной платы, предоставляемый работнику по разрешению работодателя";
	WorkingHoursKinds.Write();
	
	// ZB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Strike;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Забастовка (при условиях и в порядке, предусмотренных законом)";
	WorkingHoursKinds.Write();
	
	// TO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.BusinessTrip;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Business trip";
	WorkingHoursKinds.Write();
	
	// N.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.WorkNightHours;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Продолжительность работы в ночное время";
	WorkingHoursKinds.Write();
	
	// NB.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Отстранение от работы (недопущение к работе) по причинам, предусмотренным законодательством, без начисления заработной платы";
	WorkingHoursKinds.Write();
	
	// NV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Дополнительные выходные дни (без сохранения заработной платы)";
	WorkingHoursKinds.Write();
	
	// NZ.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.SalaryPayoffDelay;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Время приостановки работы в случае задержки выплаты заработной платы";
	WorkingHoursKinds.Write();
	
	// NN.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Неявки по невыясненным причинам (до выяснения обстоятельств)";
	WorkingHoursKinds.Write();
	
	// NO.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Отстранение от работы (недопущение к работе) с оплатой (пособием) в соответствии с законодательством";
	WorkingHoursKinds.Write();
	
	// NP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Simple;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Время простоя по причинам, не зависящим от работодателя и работника";
	WorkingHoursKinds.Write();
	
	// OV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Дополнительные выходные дни (оплачиваемые)";
	WorkingHoursKinds.Write();
	
	// OD.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.AdditionalVacation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Ежегодный дополнительный оплачиваемый отпуск";
	WorkingHoursKinds.Write();
	
	// OZH.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationByCareForBaby;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Отпуск по уходу за ребенком до достижения им возраста трех лет";
	WorkingHoursKinds.Write();
	
	// OZ.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Отпуск без сохранения заработной платы в случаях, предусмотренных законодательством";
	WorkingHoursKinds.Write();
	
	// OT.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.MainVacation;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Ежегодный основной оплачиваемый отпуск";
	WorkingHoursKinds.Write();
	
	// PV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.ForcedTruancy;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Время вынужденного прогула в случае признания увольнения, перевода на другую работу или отстранения от работы незаконными с восстановлением на прежней работе";
	WorkingHoursKinds.Write();
	
	// PK.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.QualificationRaise;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Повышение квалификации с отрывом от работы";
	WorkingHoursKinds.Write();
	
	// PM.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Повышение квалификации с отрывом от работы в другой местности";
	WorkingHoursKinds.Write();
	
	// PR.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Truancies;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Прогулы (отсутствие на рабочем месте без уважительных причин в течение времени, установленного законодательством)";
	WorkingHoursKinds.Write();
	
	// R.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Отпуск по беременности и родам (отпуск в связи с усыновлением новорожденного ребенка)";
	WorkingHoursKinds.Write();
	
	// RV.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Holidays;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Продолжительность работы в выходные и нерабочие, праздничные дни";
	WorkingHoursKinds.Write();
	
	// RP.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DowntimeByEmployerFault;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Время простоя по вине работодателя";
	WorkingHoursKinds.Write();
	
	// C.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Overtime;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Продолжительность сверхурочной работы";
	WorkingHoursKinds.Write();
	
	// T.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.DiseaseWithoutPay;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Временная нетрудоспособность без назначения пособия в случаях, предусмотренных законодательством";
	WorkingHoursKinds.Write();
	
	// Y.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationForTraining;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Дополнительный отпуск в связи с обучением с сохранением среднего заработка работникам, совмещающим работу с обучением";
	WorkingHoursKinds.Write();
	
	// YD.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Дополнительный отпуск в связи с обучением без сохранения заработной платы";
	WorkingHoursKinds.Write();
	
	// I.
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Work;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "Продолжительность работы в дневное время";
	WorkingHoursKinds.Write();
	
EndProcedure

// 5.
Procedure FillInformationAboutNewCompanyRu(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", "ООО ""Наша компания""");
	StructureCompany.Insert("Prefix", "OF-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", True);
	StructureCompany.Insert("NameOfPettyCash", "Основная касса");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure

#EndRegion

#EndRegion

#Region DefinedCountry

Function ThisIsRu(Postfix)
	Return Postfix = Upper("Ru");
EndFunction 

#EndRegion