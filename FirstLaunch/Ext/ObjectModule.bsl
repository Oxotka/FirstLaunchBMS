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


#Region DefinedCountry

Function ThisIsRu(Postfix)
	Return Postfix = Upper("Ru");
EndFunction 

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
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	//RONRef = InfobaseUpdateSB.FindCreateCurrency("946", "RON", "Leu romanesc", "RON, RON, RON, м, ban, bani, bani, м, 2");
	//RURRef = InfobaseUpdateSB.FindCreateCurrency("643", "rub.", "Russian ruble", "ruble, ruble, rubles, M, kopek, kopek, kopeks, F, 2");
	
	CurrencyRef = EURRef;
	// InfobaseUpdateSB.FindCreateCurrency("643", "rub.", "Russian ruble", "ruble, ruble, rubles, M, kopek, kopek, kopeks, F, 2");  // TODO Change for EUR
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
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
	StructureCompany.Insert("IncludeVATInPrice",     False);
	
	// ...predefined...
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
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
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
// EndRegion RU

#Region Ro

// 1.
Procedure FillTaxTypesRo()
	
	If ValueIsFilled(Catalogs.TaxTypes.FindByDescription("Accize")) Then
		Return;
	EndIf;
	
	// 000000020	Accize
	//TaxKind.Description = NStr("en='Excise';ro='';ru='Акцизы'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Accize";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();

  	// 000000010	CAS angajat
	//TaxKind.Description = NStr("en='Social fund';ro='';ru='Социальный фонд'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "CAS angajat";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
	// 000000009	CASS Angajat
	//TaxKind.Description = NStr("en='Pension Fund';ro='';ru='Удержание в пенсионный фонд'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "CASS Angajat";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000019	CCI Angajator
	//TaxKind.Description = NStr("en='Aids assurance fund';ro='';ru='Фонд обеспечения пособий'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "CCI Angajator";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000021	Comision vamal
	//TaxKind.Description = NStr("en='Customs fee';ro='';ru='Таможенный сбор'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Comision vamal";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000014	Fond de accidente
	//TaxKind.Description = NStr("en='Accident insurance fund';ro='';ru='Фонд страхования от несчастных случаев'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Fond de accidente";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();

  	// 000000015	Fond de garantare
	//TaxKind.Description = NStr("en='Guarantee fund';ro='';ru='Гарантийный фонд'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Fond de garantare";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000016	Fond de mediu
	//TaxKind.Description = NStr("en='Environment fund';ro='';ru='Фонд экологии'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Fond de mediu";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000013	Fond sanatate
	//TaxKind.Description = NStr("en='Health care fund';ro='';ru='Фонд здравоохранения'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Fond sanatate";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000028	Impozit pe alte venituri PF
	//TaxKind.Description = NStr("en='Other natural persons' incomes tax';ro='';ru='Налог на прочие доходы физ.лиц'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozit pe alte venituri PF";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();

  	// 000000024	Impozit pe cladiri
	//TaxKind.Description = NStr("en='Tax on assets';ro='';ru='Налог на недвижимость'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozit pe cladiri";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000025	Impozit pe masini
	//TaxKind.Description = NStr("en='Tax on cars';ro='';ru='Налог на транспорт'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozit pe masini";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000022	Impozit pe profit
	//TaxKind.Description = NStr("en='Profit tax';ro='';ru='Налог на прибыль'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozit pe profit";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000017	Impozit pe salarii
	//TaxKind.Description = NStr("en='Wage tax';ro='';ru='Налог на заработную плату'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozit pe salarii";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000027	Impozit pe teren
	//TaxKind.Description = NStr("en='Tax on terrains';ro='';ru='Земельный Налог'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozit pe teren";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000026	Impozit taxa firmei
	//TaxKind.Description = NStr("en='Commercial ad fee';ro='';ru='Сбор за коммерческую рекламу'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozit taxa firmei";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000023	Impozitul pe veniturile microintreprinderilor
	//TaxKind.Description = NStr("en='SME income tax';ro='';ru='Налог на доход микропредприятий'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Impozitul pe veniturile microintreprinderilor";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000008	Regularizări TVA
	//TaxKind.Description = NStr("en='VAT regulariosation';ro='';ru='Закрытие счетов НДС'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Regularizări TVA";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000011	Somaj angajat
	//TaxKind.Description = NStr("en='Unemployment tallage';ro='';ru='Удержание в фонд по безработице'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Somaj angajat";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000012	Somaj angajator
	//TaxKind.Description = NStr("en='Unemployment fund';ro='';ru='Фонд по безработице'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Somaj angajator";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000029	Taxa habitat
	//TaxKind.Description = NStr("en='Desinfection fee';ro='';ru='Сбор на дезинфекцию'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "Taxa habitat";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000003	TVA Amanunt
	//TaxKind.Description = NStr("en='VAT retail';ro='';ru='НДС в рознице'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "TVA Amanunt";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000004	TVA Colectata
	//TaxKind.Description = NStr("en='VAT Accrued';ro='';ru='НДС начисленный'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "TVA Colectata";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000005	TVA Deductibila
	//TaxKind.Description = NStr("en='VAT offset';ro='';ru='НДС к зачету'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "TVA Deductibila";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000006	TVA Neexigibila cumparari
	//TaxKind.Description = NStr("en='VAT offset deferred';ro='';ru='НДС к зачету отсроченный'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "TVA Neexigibila cumparari";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
  	// 000000007	TVA Neexigibila vanzari
	//TaxKind.Description = NStr("en='VAT accrued deferred';ro='';ru='НДС начисленный отсроченный'");
	TaxKind = Catalogs.TaxTypes.CreateItem();
	TaxKind.Description = "TVA Neexigibila vanzari";
	TaxKind.GLAccount = ChartsOfAccounts.Managerial.Taxes;
	TaxKind.GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	TaxKind.Write();
	
EndProcedure

// 2.
Procedure FillCurrencyRo(Structure)
	
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	RONRef = InfobaseUpdateSB.FindCreateCurrency("946", "RON", "Leu romanesc", "RON, RON, RON, м, ban, bani, bani, м, 2");

	CurrencyRef = RONRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	
	Structure.Insert("Currency", CurrencyRef);
	
EndProcedure


// ПОЧЕМУ НЕТ ПЕРВОНАЧАЛЬНОГО ЗАПОЛНЕНИЯ КУРСОВ ВАЛЮТ ?


// 3.
Procedure FillVATRatesRo(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("Cota TVA 20%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	
	// ...
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "";
	VATRate.Rate = ???;
	VATRate.Write();
	
	
	// 20%
	//VATRate.Description = NStr("en='VAT rate 20%';ro='';ru='Ставка НДС 20%'");
	VATRate = Catalogs.VATRates.CreateItem();
	VATRate.Description = "Cota TVA 20%";
	VATRate.Rate = 20;
	VATRate.Write();
	
	
	//// 20%
	//VATRate.Description = NStr("en='VAT rate 20%';ro='';ru='Ставка НДС 20%'");
	//VATRate.Rate 		= 20;	
	//// Cota TVA 20% fara drept de deducere
	//VATRate.Description = NStr("en='VAT rate 20% w/o offset right';ro='Cota TVA 20% fara drept de deducere';ru='Ставка НДС 20% без права зачета'");
	//VATRate.Rate 		= 20;	
	//// Taxare inversă cu cota TVA  20%
	//VATRate.Description = NStr("en='Reversed VAT 20%';ro='Taxare inversă cu cota TVA 20%';ru='Взаимозачет со ставкой НДС 20%'");
	//VATRate.Rate 		= 0;	
	//// Taxare inversă servicii intangibile cu cota TVA 20%
	//VATRate.Description = NStr("en='Reversed VAT, intangibles 20%';ro='Taxare inversă servicii intangibile cu cota TVA 20%';ru='Взаимозачет со ставкой НДС 20% (intangibile)'");
	//VATRate.Rate 		= 0;	
	//// TVA la Import din UE cu cota TVA 20%
	//VATRate.Description = NStr("en='Import VAT from EU 20%';ro='TVA la Import din UE cu cota TVA 20%';ru='НДС на импорт из ЕС со ставкой 20%'");
	//VATRate.Rate 		= 0;	
	//// 5%
	//VATRate.Description = NStr("en='VAT rate 5%';ro='Cota TVA 5%';ru='Ставка НДС 5%'");
	//VATRate.Rate 		= 5;	
	////Cota TVA 5% fara drept de deducere
	//VATRate.Description = NStr("en='VAT rate 5% w/o offset right';ro='Cota TVA 5% fara drept de deducere';ru='Ставка НДС 5% без права зачета'");
	//VATRate.Rate 		= 5;	
	//// 9%
	//VATRate.Description = NStr("en='VAT rate 9%';ro='Cota TVA 9%';ru='Ставка НДС 9%'");
	//VATRate.Rate 		= 9;	
	////Cota TVA 9% fara drept de deducere
	//VATRate.Description = NStr("en='VAT rate 9% w/o offset right';ro='Cota TVA 9% fara drept de deducere';ru='Ставка НДС 9% без права зачета'");
	//VATRate.Rate 		= 9;	
	//// TVA Neimpozabile
	//VATRate.Description = NStr("en='Non-taxable';ro='TVA Neimpozabile';ru='НДС Необлагаемый'");
	//VATRate.Rate 		= 0;	
	//// TVA NeimpozabileEU - Neimpozabile la import din UE destinate revănzării
	//VATRate.Description = NStr("en='Non-taxable EU';ro='TVA Neimpozabile EU';ru='НДС Необлагаемый ЕС'");
	//VATRate.Rate 		= 0;	
	//// Scutite cu drept de deducere
	//VATRate.Description = NStr("en='VAT exempt w/offset right';ro='Scutite cu drept de deducere';ru='Освобожденные с правом зачета'");
	//VATRate.Rate 		= 0;	
	//// Scutite fara drept de deducere
	//VATRate.Description = NStr("en='VAT exempt w/o offset right';ro='Scutite fara drept de deducere';ru='Освобожденные без права зачета'");
	//VATRate.Rate 		= 0;	
	//// Scutite la Export cu drept de deducere
	//VATRate.Description = NStr("en='Export VAT exempt w offset right';ro='Scutite la Export cu drept de deducere';ru='Освобожденные на экспорт с правом зачета'");
	//VATRate.Rate 		= 0;	
	//// Scutite la Export cu drept de deducere conf. art.143 alin.1 lit.c) și d)
	//VATRate.Description = NStr("en='Export VAT exempt w offset right - § C, D';ro='Scutite la Export cu drept de deducere conf. art.143 alin.1 lit.c) și d)';ru='Освобожденные на экспорт с правом зачета согласно п.143 § C, D'");
	//VATRate.Rate 		= 0;	
	//// Scutite la Export fără drept de deducere
	//VATRate.Description = NStr("en='Export VAT exempt w/o offset right';ro='Scutite la Export fără drept de deducere';ru='Освобожденные на экспорт без права зачета'");
	//VATRate.Rate 		= 0;	
	//// Scutite la Export in UE conf. art.143 alin.2 lit.a) și d)
	//VATRate.Description = NStr("en='Export VAT exempt w offset right (EU)- § A, D';ro='Scutite la Export in UE conf. art.143 alin.2 lit.a) și d)';ru='Освобожденные на экспортв ЕС с правом зачета согласно п.143 § A, D'");
	//VATRate.Rate 		= 0;	
	//// Scutite la Export in UE conf. art.143 alin.2 lit.b) și c)
	//VATRate.Description = NStr("en='Export VAT exempt w offset right (EU) § B, C';ro='Scutite la Export in UE conf. art.143 alin.2 lit.b) și c)';ru='Освобожденные на экспорт с правом зачета согласно п.143 § B, C'");
	//VATRate.Rate 		= 0;	
	//// Scutite la Import din UE destinate revănzării
	//VATRate.Description = NStr("en='Import from EU VAT exempt, to resell';ro='Scutite la Import din UE destinate revănzării';ru='Освобожденный импорт из ЕС с целью перепродажи'");
	//VATRate.Rate 		= 0;	
	//// Scutite la Import din UE pentru nevoile firmei
	//VATRate.Description = NStr("en='Import from EU VAT exempt, internal use';ro='Scutite la Import din UE pentru nevoile firmei';ru='Освобожденный импорт из ЕС для внутр.использования'");
	//VATRate.Rate 		= 0;	
	
	
	
	Structure.Insert("VAT", VATRate.Ref);
	
EndProcedure

// 4. 
Procedure FillClassifierOfWorkingTimeUsageRo()
	
	// ....
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Disease;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "";
	WorkingHoursKinds.Write();
	

	
	///////////////////////////////////////////////////////////////////////////////
	// Disease	6	DS
    OfficeHoursKinds.FullDescr	= NStr("en = 'Temporary disability with benefit allocation according to legislation'; 
									   |ro = 'Incapacitate temporară de muncă cu alocare de beneficii în conformitate cu legislația'; 
									   |ru = 'Temporary disability with benefit allocation according to legislation'");

    // WeekEnd	1	WE 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Days off (weekly vacation) and nonworking holidays'; 
	                                    |ro = 'Zile libere ( vacanța săptămânală ) și vacanțe nelucrătoare'; 
								        |ru = 'Days off (weekly vacation) and nonworking holidays'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Dead time by the employees fault'; 
	                                    |ro = 'Timp pierdut din vina angajaților'; 
								        |ru = 'Dead time by the employees fault'");

	// 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Work duration in afternoon time'; 
	                                    |ro = 'Activitate normală după-amiaza'; 
								        |ru = 'Work duration in afternoon time'");

    // y.
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Unjustified absence during state or social duties according to legislation'; 
	                                    |ro = 'Absența nejustificată în timpul datoriilor sociale sau de stat în conformitate cu legislația'; 
								        |ru = 'Unjustified absence during state or social duties according to legislation'");

    // DB.
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Annual additional vacation without wage maintenance'; 
	                                    |ro = 'Vacanță anuală suplimentară neplătită'; 
								        |ru = 'Annual additional vacation without wage maintenance'");

    // TO.
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Vacation without wage maintanance, given to the employee by the employers permission'; 
	                                    |ro = 'Vacanță neplătită a angajatului cu permisiunea angajatorului'; 
								        |ru = 'Vacation without wage maintanance, given to the employee by the employers permission'");;

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Strike (in conditions and order, provided by legislation)'; 
	                                    |ro = 'Greva (in condițiile prevazute de lege)'; 
								        |ru = 'Strike (in conditions and order, provided by legislation)'");

    // TO.
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Service BusinessTrip'; 
	                                    |ro = 'Deplasări în interes de serviciu'; 
								        |ru = 'Service BusinessTrip'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Duration works In night Time'; 
	                                    |ro = 'Activitate pe timp de noapte'; 
								        |ru = 'Duration works In night Time'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Dismissal from work (exclusion from work) by reasons, covered by legislation, without wage charging'; 
	                                    |ro = 'Concedierea de la locul de muncă ( excludere de la locul de muncă ) din motive , acceptate de legislație , fără plata salariului'; 
								        |ru = 'Dismissal from work (exclusion from work) by reasons, covered by legislation, without wage charging'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional days off (without wage maintanance)'; 
	                                    |ro = 'Zile libere suplimentare neplătite'; 
								        |ru = 'Additional days off (without wage maintanance)'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Time of work interruption in case of wages payout delay'; 
	                                    |ro = 'Întreruperea activității datorită înârzierii plații salariale'; 
								        |ru = 'Time of work interruption in case of wages payout delay'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Absence by the unclarified reasons (before clarifying reasons)'; 
	                                    |ro = 'Absentarea de la locul de muncă din motive nespecificate (sau înainte de clarificarea lor)'; 
								        |ru = 'Absence by the unclarified reasons (before clarifying reasons)'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Dismissal from work (exclusion from work) with payouts (aid) according to legislation'; 
	                                    |ro = 'Concedierea de la locul de muncă ( de excludere de la locul de muncă ) cu plată ( ajutor ) în conformitate cu legislația'; 
								        |ru = 'Dismissal from work (exclusion from work) with payouts (aid) according to legislation'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Dead time by reasons, not depending on employer and employee'; 
	                                    |ro = 'Inactivitatea angajaților din motive ce nu depind de angajat sau angajator'; 
								        |ru = 'Dead time by reasons, not depending on employer and employee'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional days off (payable)'; 
	                                    |ro = 'Zile libere suplimentare plătite'; 
								        |ru = 'Additional days off (payable)'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Annual Additional Paid vacation'; 
	                                    |ro = 'Concediu anual suplimentar plătit'; 
								        |ru = 'Annual Additional Paid vacation'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Baby-sitting vacation before his three year old attainment'; 
	                                    |ro = 'Concediu de maternitate postnatal'; 
								        |ru = 'Baby-sitting vacation before his three year old attainment'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Vacation without wage maintanance in cases, covered by legislation'; 
	                                    |ro = 'Concediu neplătit în cazurile reglementate de legislație'; 
								        |ru = 'Vacation without wage maintanance in cases, covered by legislation'");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Main annual payable vacation'; 
	                                    |ro = 'Concediu anual plătit'; 
								        |ru = 'Main annual payable vacation");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Time of forced abcense in case of dismissal acknowledgment, remittance or deletion of work by illegal with reinstatement'; 
	                                    |ro = 'Încetarea temporară a activității'; 
								        |ru = 'Time of forced abcense in case of dismissal acknowledgment, remittance or deletion of work by illegal with reinstatement");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Advanced training with work interruption'; 
	                                    |ro = 'Intstruire avansată cu întrerupere de activitate'; 
								        |ru = 'Advanced training with work interruption");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Advanced training with work interruption in different region'; 
	                                    |ro = 'Intstruire avansată cu întrerupere de activitate în diferite regiuni'; 
								        |ru = 'Advanced training with work interruption in different region");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Miss-outs (absences at work place without reasonable excuse during time, established under legislation'; 
	                                    |ro = 'Absențe de la locul de muncă fară scuze plauzibile în conformitate cu legislația'; 
								        |ru = 'Miss-outs (absences at work place without reasonable excuse during time, established under legislation");

    // 
    OfficeHoursKinds.FullDescr	=  NStr ("en = 'Maternity leave (vacation because of newborn baby adoption)'; 
	                                     |ro = 'Concediu de maternitate prenatal'; 
								         |ru = 'Maternity leave (vacation because of newborn baby adoption)");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Work duration during days off and nonworking days, holidays'; 
	                                    |ro = 'Activitate în timpul zilelor libere, zilelor nelucrătoare și sărbatorilor'; 
								        |ru = 'Work duration during days off and nonworking days, holidays");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Dead time by employers fault'; 
	                                    |ro = 'Inactivitate din vina angajatorului'; 
								        |ru = 'Dead time by employers fault");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Overtime duration'; 
	                                    |ro = 'Ore suplimentare'; 
								        |ru = 'Overtime duration");

    // T.
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Temporary disability without benefit allocation in cases, covered to legislation'; 
	                                    |ro = 'Incapacitate temporară de muncă, fără alocare de beneficii in unele cazuri prevăzute de legislație'; 
								        |ru = 'Temporary disability without benefit allocation in cases, covered to legislation");

    // 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional vacation because of studies with employees average earnings saving,combining work and studies'; 
	                                    |ro = 'Concediu de studiu plătit în care se îmbina munca cu studiul'; 
								        |ru = 'Additional vacation because of studies with employees average earnings saving,combining work and studies");

	// 
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional vacation because of studies without wages maintanance'; 
	                                    |ro = 'Concediu de studiu neplătit'; 
								        |ru = 'Additional vacation because of studies without wages maintanance");

	// I.
    OfficeHoursKinds.FullDescr	= NStr ("en = 'Work duration in day time'; 
	                                    |ro = 'Activitate normală pe timp de zi'; 
								        |ru = 'Work duration in day time");

	
	
EndProcedure

// 5.
Procedure FillInformationAboutNewCompanyRo(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", "Firma Noastra SRL");
	StructureCompany.Insert("Prefix", "FN-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", False);
	
	// valuta
	StructureCompany.Insert("NameOfPettyCash", "Casa Principala");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure

// В КАЖДОЙ СТРАНЕ - СВОЯ ПЯТИДНЕВКА ?

#EndRegion    
// EndRegion RO

#EndRegion
