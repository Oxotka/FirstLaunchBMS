// The procedure consists of two parts:
// 1. PredifenedDataAtServer
// In this procedure execute the filling of taxes, VAT rates, currencies and classifier working time.
// Also in this procedure is forming information about company.
// This information will be show user and will can changed.
// 2. CreateCompany
// In this procedure execute filling predifened company, create PettyCash and prices kind.
// 

// Function start filling data for choisen country
// 1. Fill in tax types 
// 2. Fill in currency 
// 3. Fill in VAT rates. 
// 4. Fill in classifier of the working time use.
// 5. Fill in description of company.
// Parameters:
//  - Postfix - string - Symbol of the country, for example Ru - Russia, Ro - Romania.
//
Function PredifenedDataAtServer(Postfix) Export
	
	Structure = New Structure;
	Postfix   = Upper(Postfix);
	
	PredifenedDateAtServerForCountry(Structure, Postfix);
	
	Return Structure;
	
EndFunction

// Function fill information about company
// 1. Fill in company
// 2. Fill in petty cash
// 3. Fill in prices kind
// 
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
	
	// 1. Fill in tax types
	FillTaxTypes(Postfix);
	// 2. Fill in currencies
	FillCurrency(Structure, Postfix);
	// 3. Fill in VAT rates.
	FillVATRates(Structure, Postfix);
	// 4. Fill in classifier of the working time use.
	FillClassifierOfWorkingTimeUsage(Postfix);
	// 5. Fill in description of company.
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

#Region OtherProcedures

Function NewTaxType(Description, GLAccount = Undefined, GLAccountForReimbursement = Undefined)
	
	If GLAccount = Undefined Then
		GLAccount = ChartsOfAccounts.Managerial.Taxes;
	EndIf;
	If GLAccountForReimbursement = Undefined Then
		GLAccountForReimbursement = ChartsOfAccounts.Managerial.TaxesToRefund;
	EndIf;
	
	TaxType = New Structure;
	TaxType.Insert("Description", Description);
	TaxType.Insert("GLAccount", GLAccount);
	TaxType.Insert("GLAccountForReimbursement", GLAccountForReimbursement);
	
	Return TaxType;
	
EndFunction

Procedure FillTaxTypesFromArray(ArrayOfTaxTypes)

	If ArrayOfTaxTypes.Count() = 0 Then
		Return;
	EndIf;
	
	FirstTaxType = ArrayOfTaxTypes[0];
	If ValueIsFilled(Catalogs.TaxTypes.FindByDescription(FirstTaxType.Description)) Then
		Return;
	EndIf;
	
	For Each TaxType In ArrayOfTaxTypes Do
		TaxKind = Catalogs.TaxTypes.CreateItem();
		FillPropertyValues(TaxKind, TaxType);
		TaxKind.Write();
	EndDo;

EndProcedure

Function NewVATRate(Description, Rate, Calculated = False, NotTaxable = False)

	NewVATRate = New Structure;
	NewVATRate.Insert("Description", Description);
	NewVATRate.Insert("Rate", Rate);
	NewVATRate.Insert("Calculated", Calculated);
	NewVATRate.Insert("NotTaxable", NotTaxable);
	
	Return NewVATRate;

EndFunction

Procedure FillVATRateFormArray(ArrayOfVATRates)

	If ArrayOfVATRates.Count() = 0 Then
		Return;
	EndIf;
	
	For Each ValueTaxRate In ArrayOfVATRates Do
		VATRate = Catalogs.VATRates.CreateItem();
		FillPropertyValues(VATRate, ValueTaxRate);
		VATRate.Write();
	EndDo;
	
EndProcedure

Function NewStructureCurrencyRate(Currency, Period, ExchangeRate = 1, Multiplicity = 1);
	
	StructureCurrencyRate = New Structure;
	StructureCurrencyRate.Insert("Currency",     Currency);
	StructureCurrencyRate.Insert("Period",       Period);
	StructureCurrencyRate.Insert("ExchangeRate", ExchangeRate);
	StructureCurrencyRate.Insert("Multiplicity", Multiplicity);
	Return StructureCurrencyRate;
	
EndFunction

Procedure FillCurrencyRatesFromStructure(StructureCurrencyRate)
	
	RecordSet = InformationRegisters.CurrencyRates.CreateRecordSet();
	RecordSet.Filter.Currency.Set(StructureCurrencyRate.Currency);
	
	Record = RecordSet.Add();
	FillPropertyValues(Record, StructureCurrencyRate);
	RecordSet.AdditionalProperties.Insert("SkipChangeProhibitionCheck");
	RecordSet.Write();
	
EndProcedure

Procedure FillClassifierOfWorkingTimeUsageFormMap(MapClassifierOfWorkingTimeUsage)
	
	For Each ClassifierWorkingHoursKinds In MapClassifierOfWorkingTimeUsage Do
		WorkingHoursKinds = ClassifierWorkingHoursKinds.Key.GetObject();
		WorkingHoursKinds.FullDescr = ClassifierWorkingHoursKinds.Value;
		WorkingHoursKinds.Write();
	EndDo;
	
EndProcedure

#EndRegion

#Region DefinedCountry

Function ThisIsRu(Postfix)
	Return Postfix = Upper("Ru");
EndFunction 

#EndRegion

#Region ProceduresForCountry

#Region Default

Procedure FillTaxTypesDefault()
	
	ArrayOfTaxTypes = New Array;
	ArrayOfTaxTypes.Add(NewTaxType("VAT"));
	ArrayOfTaxTypes.Add(NewTaxType("Income tax"));
	
	FillTaxTypesFromArray(ArrayOfTaxTypes);
	
EndProcedure

Procedure FillCurrencyDefault(Structure)
	
	// Fill in currencies.
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	//RONRef = InfobaseUpdateSB.FindCreateCurrency("946", "RON", "Leu romanesc", "RON, RON, RON, м, ban, bani, bani, м, 2");
	//RURRef = InfobaseUpdateSB.FindCreateCurrency("643", "rub.", "Russian ruble", "ruble, ruble, rubles, M, kopek, kopek, kopeks, F, 2");
	
	CurrencyRef = EURRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
	Constants.FunctionalCurrencyTransactionsAccounting.Set(False);
	
	Structure.Insert("Currency", CurrencyRef);
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), 1.0882);
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	
EndProcedure

Procedure FillVATRatesDefault(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("18%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	ArrayOfVATRates = New Array;
	ArrayOfVATRates.Add(NewVATRate("10%", 10));
	ArrayOfVATRates.Add(NewVATRate("18% / 118%", 18, True));
	ArrayOfVATRates.Add(NewVATRate("10% / 110%", 10, True));
	ArrayOfVATRates.Add(NewVATRate("0%", 0));
	ArrayOfVATRates.Add(NewVATRate("Without VAT", 0,,True));
	ArrayOfVATRates.Add(NewVATRate("18%", 18));
	
	FillVATRateFormArray(ArrayOfVATRates);
	
	Structure.Insert("VAT", Catalogs.VATRates.FindByDescription("18%"));
	
EndProcedure

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

Procedure FillInformationAboutNewCompanyDefault(Structure)
	
	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull",       "LLC ""Our company""");
	StructureCompany.Insert("Prefix",                "OF-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice",     False);
	
	// PettyCash create in CreateCompany(), because now we do not know the accounting currency.
	// At this moment assign the name of the main petty cash. 
	StructureCompany.Insert("NameOfPettyCash",       "Main petty cash");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure

#EndRegion

#Region Ru

Procedure FillTaxTypesRu()
	
	ArrayOfTaxTypes = New Array;
	ArrayOfTaxTypes.Add(NewTaxType("НДС"));
	ArrayOfTaxTypes.Add(NewTaxType("Налог на прибыль"));
	
	FillTaxTypesFromArray(ArrayOfTaxTypes);
	
EndProcedure

Procedure FillCurrencyRu(Structure)
	
	CurrencyRef = InfobaseUpdateSB.FindCreateCurrency("643", "руб.", "Российский рубль", "рубль, рубля, рублей, M, копейка, копейки, копеек, F, 2");
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// Если используется несколько валют, то следует включить эту опцию, чтобы отображался блок с валютами.
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	Structure.Insert("Currency", CurrencyRef);
	
EndProcedure

Procedure FillVATRatesRu(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("18%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	ArrayOfVATRates = New Array;
	ArrayOfVATRates.Add(NewVATRate("10%", 10));
	ArrayOfVATRates.Add(NewVATRate("18% / 118%", 18, True));
	ArrayOfVATRates.Add(NewVATRate("10% / 110%", 10, True));
	ArrayOfVATRates.Add(NewVATRate("0%", 0));
	ArrayOfVATRates.Add(NewVATRate("Без НДС", 0,,True));
	ArrayOfVATRates.Add(NewVATRate("18%", 18));
	
	FillVATRateFormArray(ArrayOfVATRates);
	
	Structure.Insert("VAT", Catalogs.VATRates.FindByDescription("18%"));
	
EndProcedure

Procedure FillClassifierOfWorkingTimeUsageRu()
	
	MapClassifierOfWorkingTimeUsage = New Map;
	// B.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Disease,
		"Временная нетрудоспособность с назначением пособия согласно законодательству");
	// V.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WeekEnd,
		"Выходные дни (еженедельный отпуск) и  нерабочие праздничные дни");
	// VP.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault,
		"Простои по вине работника");
	
	// VCH.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkEveningClock,
		"Продолжительность работы в вечернее время");
	
	// G.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.PublicResponsibilities,
		"Невыходы на время исполнения государственных или общественных обязанностей согласно законодательству");

	// DB.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation,
		"Ежегодный дополнительный отпуск без сохранения заработной платы");
		
	// TO.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission,
		"Отпуск без сохранения заработной платы, предоставляемый работнику по разрешению работодателя");
	
	// ZB.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Strike,
		"Забастовка (при условиях и в порядке, предусмотренных законом)");
	
	// TO.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.BusinessTrip,
		"Рабочая командировка");
	
	// N.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkNightHours,
		"Продолжительность работы в ночное время");
	
	// NB.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments,
		"Отстранение от работы (недопущение к работе) по причинам, предусмотренным законодательством, без начисления заработной платы");
	
	// NV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid,
		"Дополнительные выходные дни (без сохранения заработной платы)");
	
	// NZ.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.SalaryPayoffDelay,
		"Время приостановки работы в случае задержки выплаты заработной платы");
	
	// NN.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons,
		"Неявки по невыясненным причинам (до выяснения обстоятельств)");
	
	// NO.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment,
		"Отстранение от работы (недопущение к работе) с оплатой (пособием) в соответствии с законодательством");
	
	// NP.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Simple,
		"Время простоя по причинам, не зависящим от работодателя и работника");
	
	// OV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid,
		"Дополнительные выходные дни (оплачиваемые)");
	
	// OD.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalVacation,
		"Ежегодный дополнительный оплачиваемый отпуск");
	
	// OZH.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByCareForBaby,
		"Отпуск по уходу за ребенком до достижения им возраста трех лет");
	
	// OZ.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation,
		"Отпуск без сохранения заработной платы в случаях, предусмотренных законодательством");
	
	// OT.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.MainVacation,
		"Ежегодный основной оплачиваемый отпуск");
	
	// PV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.ForcedTruancy,
		"Время вынужденного прогула в случае признания увольнения, перевода на другую работу или отстранения от работы незаконными с восстановлением на прежней работе");
	
	// PK.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaise,
		"Повышение квалификации с отрывом от работы");
	
	// PM.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain,
		"Повышение квалификации с отрывом от работы в другой местности");
	
	// PR.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Truancies,
		"Прогулы (отсутствие на рабочем месте без уважительных причин в течение времени, установленного законодательством)");
	
	// R.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth,
		"Отпуск по беременности и родам (отпуск в связи с усыновлением новорожденного ребенка)");
	
	// RV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Holidays,
		"Продолжительность работы в выходные и нерабочие, праздничные дни");
	
	// RP.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployerFault,
		"Время простоя по вине работодателя");
	
	// C.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Overtime,
		"Продолжительность сверхурочной работы");
	
	// T.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DiseaseWithoutPay,
		"Временная нетрудоспособность без назначения пособия в случаях, предусмотренных законодательством");
	
	// Y.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTraining,
		"Дополнительный отпуск в связи с обучением с сохранением среднего заработка работникам, совмещающим работу с обучением");
	
	// YD.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid,
		"Дополнительный отпуск в связи с обучением без сохранения заработной платы");
	
	// I.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Work,
		"Продолжительность работы в дневное время");
		
	FillClassifierOfWorkingTimeUsageFormMap(MapClassifierOfWorkingTimeUsage);
	
EndProcedure

Procedure FillInformationAboutNewCompanyRu(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", "ООО ""Наша компания""");
	StructureCompany.Insert("Prefix", "OF-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", True);
	
	// Касса создается в CreateCompany(), потому что сейчас мы не знаем валюту учета.
	// В данный момент зададим имя основной кассы.
	StructureCompany.Insert("NameOfPettyCash", "Основная касса");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure

#EndRegion
// EndRegion RU

#Region Ro

Procedure FillTaxTypesRo()
	
	ArrayOfTaxTypes = New Array;
	
	// 000000020	Accize
	//TaxKind.Description = NStr("en='Excise';ro='';ru='Акцизы'");
	ArrayOfTaxTypes.Add(NewTaxType("Accize"));
	
	// 000000010	CAS angajat
	//TaxKind.Description = NStr("en='Social fund';ro='';ru='Социальный фонд'");
	ArrayOfTaxTypes.Add(NewTaxType("CAS angajat"));
	
	// 000000009	CASS Angajat
	//TaxKind.Description = NStr("en='Pension Fund';ro='';ru='Удержание в пенсионный фонд'");
	ArrayOfTaxTypes.Add(NewTaxType("CASS Angajat"));
	
	// 000000019	CCI Angajator
	//TaxKind.Description = NStr("en='Aids assurance fund';ro='';ru='Фонд обеспечения пособий'");
	ArrayOfTaxTypes.Add(NewTaxType("CCI Angajator"));
	
	// 000000021	Comision vamal
	//TaxKind.Description = NStr("en='Customs fee';ro='';ru='Таможенный сбор'");
	ArrayOfTaxTypes.Add(NewTaxType("Comision vamal"));
	
	// 000000014	Fond de accidente
	//TaxKind.Description = NStr("en='Accident insurance fund';ro='';ru='Фонд страхования от несчастных случаев'");
	ArrayOfTaxTypes.Add(NewTaxType("Fond de accidente"));

  	// 000000015	Fond de garantare
	//TaxKind.Description = NStr("en='Guarantee fund';ro='';ru='Гарантийный фонд'");
	ArrayOfTaxTypes.Add(NewTaxType("Fond de garantare"));
	
  	// 000000016	Fond de mediu
	//TaxKind.Description = NStr("en='Environment fund';ro='';ru='Фонд экологии'");
	ArrayOfTaxTypes.Add(NewTaxType("Fond de mediu"));
	
  	// 000000013	Fond sanatate
	//TaxKind.Description = NStr("en='Health care fund';ro='';ru='Фонд здравоохранения'");
	ArrayOfTaxTypes.Add(NewTaxType("Fond sanatate"));
	
  	// 000000028	Impozit pe alte venituri PF
	//TaxKind.Description = NStr("en='Other natural persons' incomes tax';ro='';ru='Налог на прочие доходы физ.лиц'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozit pe alte venituri PF"));

  	// 000000024	Impozit pe cladiri
	//TaxKind.Description = NStr("en='Tax on assets';ro='';ru='Налог на недвижимость'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozit pe cladiri"));
	
  	// 000000025	Impozit pe masini
	//TaxKind.Description = NStr("en='Tax on cars';ro='';ru='Налог на транспорт'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozit pe masini"));
	
  	// 000000022	Impozit pe profit
	//TaxKind.Description = NStr("en='Profit tax';ro='';ru='Налог на прибыль'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozit pe profit"));
	
  	// 000000017	Impozit pe salarii
	//TaxKind.Description = NStr("en='Wage tax';ro='';ru='Налог на заработную плату'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozit pe salarii"));
	
  	// 000000027	Impozit pe teren
	//TaxKind.Description = NStr("en='Tax on terrains';ro='';ru='Земельный Налог'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozit pe teren"));
	
  	// 000000026	Impozit taxa firmei
	//TaxKind.Description = NStr("en='Commercial ad fee';ro='';ru='Сбор за коммерческую рекламу'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozit taxa firmei"));
	
  	// 000000023	Impozitul pe veniturile microintreprinderilor
	//TaxKind.Description = NStr("en='SME income tax';ro='';ru='Налог на доход микропредприятий'");
	ArrayOfTaxTypes.Add(NewTaxType("Impozitul pe veniturile microintreprinderilor"));
	
  	// 000000008	Regularizări TVA
	//TaxKind.Description = NStr("en='VAT regulariosation';ro='';ru='Закрытие счетов НДС'");
	ArrayOfTaxTypes.Add(NewTaxType("Regularizări TVA"));
	
  	// 000000011	Somaj angajat
	//TaxKind.Description = NStr("en='Unemployment tallage';ro='';ru='Удержание в фонд по безработице'");
	ArrayOfTaxTypes.Add(NewTaxType("Somaj angajat"));
	
  	// 000000012	Somaj angajator
	//TaxKind.Description = NStr("en='Unemployment fund';ro='';ru='Фонд по безработице'");
	ArrayOfTaxTypes.Add(NewTaxType("Somaj angajator"));
	
  	// 000000029	Taxa habitat
	//TaxKind.Description = NStr("en='Desinfection fee';ro='';ru='Сбор на дезинфекцию'");
	ArrayOfTaxTypes.Add(NewTaxType("Taxa habitat"));
	
  	// 000000003	TVA Amanunt
	//TaxKind.Description = NStr("en='VAT retail';ro='';ru='НДС в рознице'");
	ArrayOfTaxTypes.Add(NewTaxType("TVA Amanunt"));
	
  	// 000000004	TVA Colectata
	//TaxKind.Description = NStr("en='VAT Accrued';ro='';ru='НДС начисленный'");
	ArrayOfTaxTypes.Add(NewTaxType("TVA Colectata"));
	
  	// 000000005	TVA Deductibila
	//TaxKind.Description = NStr("en='VAT offset';ro='';ru='НДС к зачету'");
	ArrayOfTaxTypes.Add(NewTaxType("TVA Deductibila"));
	
  	// 000000006	TVA Neexigibila cumparari
	//TaxKind.Description = NStr("en='VAT offset deferred';ro='';ru='НДС к зачету отсроченный'");
	ArrayOfTaxTypes.Add(NewTaxType("TVA Neexigibila cumparari"));
	
  	// 000000007	TVA Neexigibila vanzari
	//TaxKind.Description = NStr("en='VAT accrued deferred';ro='';ru='НДС начисленный отсроченный'");
	ArrayOfTaxTypes.Add(NewTaxType("TVA Neexigibila vanzari"));
	
	FillTaxTypesFromArray(ArrayOfTaxTypes);
	
EndProcedure

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
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), 1.0882);
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	
EndProcedure

Procedure FillVATRatesRo(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("Cota TVA 20%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	
	//// ...
	//VATRate = Catalogs.VATRates.CreateItem();
	//VATRate.Description = "";
	//VATRate.Rate = ???;
	//VATRate.Write();
	//
	
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

Procedure FillClassifierOfWorkingTimeUsageRo()
	
	// ....
	WorkingHoursKindsReference = Catalogs.WorkingHoursKinds.Disease;
	WorkingHoursKinds = WorkingHoursKindsReference.GetObject();
	WorkingHoursKinds.FullDescr = "";
	WorkingHoursKinds.Write();
	

	
	/////////////////////////////////////////////////////////////////////////////////
	//// Disease	6	DS
	//OfficeHoursKinds.FullDescr	= NStr("en = 'Temporary disability with benefit allocation according to legislation'; 
	//								   |ro = 'Incapacitate temporară de muncă cu alocare de beneficii în conformitate cu legislația'; 
	//								   |ru = 'Temporary disability with benefit allocation according to legislation'");

	//// WeekEnd	1	WE 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Days off (weekly vacation) and nonworking holidays'; 
	//                                    |ro = 'Zile libere ( vacanța săptămânală ) și vacanțe nelucrătoare'; 
	//							        |ru = 'Days off (weekly vacation) and nonworking holidays'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Dead time by the employees fault'; 
	//                                    |ro = 'Timp pierdut din vina angajaților'; 
	//							        |ru = 'Dead time by the employees fault'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Work duration in afternoon time'; 
	//                                    |ro = 'Activitate normală după-amiaza'; 
	//							        |ru = 'Work duration in afternoon time'");

	//// y.
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Unjustified absence during state or social duties according to legislation'; 
	//                                    |ro = 'Absența nejustificată în timpul datoriilor sociale sau de stat în conformitate cu legislația'; 
	//							        |ru = 'Unjustified absence during state or social duties according to legislation'");

	//// DB.
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Annual additional vacation without wage maintenance'; 
	//                                    |ro = 'Vacanță anuală suplimentară neplătită'; 
	//							        |ru = 'Annual additional vacation without wage maintenance'");

	//// TO.
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Vacation without wage maintanance, given to the employee by the employers permission'; 
	//                                    |ro = 'Vacanță neplătită a angajatului cu permisiunea angajatorului'; 
	//							        |ru = 'Vacation without wage maintanance, given to the employee by the employers permission'");;

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Strike (in conditions and order, provided by legislation)'; 
	//                                    |ro = 'Greva (in condițiile prevazute de lege)'; 
	//							        |ru = 'Strike (in conditions and order, provided by legislation)'");

	//// TO.
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Service BusinessTrip'; 
	//                                    |ro = 'Deplasări în interes de serviciu'; 
	//							        |ru = 'Service BusinessTrip'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Duration works In night Time'; 
	//                                    |ro = 'Activitate pe timp de noapte'; 
	//							        |ru = 'Duration works In night Time'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Dismissal from work (exclusion from work) by reasons, covered by legislation, without wage charging'; 
	//                                    |ro = 'Concedierea de la locul de muncă ( excludere de la locul de muncă ) din motive , acceptate de legislație , fără plata salariului'; 
	//							        |ru = 'Dismissal from work (exclusion from work) by reasons, covered by legislation, without wage charging'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional days off (without wage maintanance)'; 
	//                                    |ro = 'Zile libere suplimentare neplătite'; 
	//							        |ru = 'Additional days off (without wage maintanance)'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Time of work interruption in case of wages payout delay'; 
	//                                    |ro = 'Întreruperea activității datorită înârzierii plații salariale'; 
	//							        |ru = 'Time of work interruption in case of wages payout delay'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Absence by the unclarified reasons (before clarifying reasons)'; 
	//                                    |ro = 'Absentarea de la locul de muncă din motive nespecificate (sau înainte de clarificarea lor)'; 
	//							        |ru = 'Absence by the unclarified reasons (before clarifying reasons)'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Dismissal from work (exclusion from work) with payouts (aid) according to legislation'; 
	//                                    |ro = 'Concedierea de la locul de muncă ( de excludere de la locul de muncă ) cu plată ( ajutor ) în conformitate cu legislația'; 
	//							        |ru = 'Dismissal from work (exclusion from work) with payouts (aid) according to legislation'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Dead time by reasons, not depending on employer and employee'; 
	//                                    |ro = 'Inactivitatea angajaților din motive ce nu depind de angajat sau angajator'; 
	//							        |ru = 'Dead time by reasons, not depending on employer and employee'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional days off (payable)'; 
	//                                    |ro = 'Zile libere suplimentare plătite'; 
	//							        |ru = 'Additional days off (payable)'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Annual Additional Paid vacation'; 
	//                                    |ro = 'Concediu anual suplimentar plătit'; 
	//							        |ru = 'Annual Additional Paid vacation'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Baby-sitting vacation before his three year old attainment'; 
	//                                    |ro = 'Concediu de maternitate postnatal'; 
	//							        |ru = 'Baby-sitting vacation before his three year old attainment'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Vacation without wage maintanance in cases, covered by legislation'; 
	//                                    |ro = 'Concediu neplătit în cazurile reglementate de legislație'; 
	//							        |ru = 'Vacation without wage maintanance in cases, covered by legislation'");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Main annual payable vacation'; 
	//                                    |ro = 'Concediu anual plătit'; 
	//							        |ru = 'Main annual payable vacation");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Time of forced abcense in case of dismissal acknowledgment, remittance or deletion of work by illegal with reinstatement'; 
	//                                    |ro = 'Încetarea temporară a activității'; 
	//							        |ru = 'Time of forced abcense in case of dismissal acknowledgment, remittance or deletion of work by illegal with reinstatement");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Advanced training with work interruption'; 
	//                                    |ro = 'Intstruire avansată cu întrerupere de activitate'; 
	//							        |ru = 'Advanced training with work interruption");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Advanced training with work interruption in different region'; 
	//                                    |ro = 'Intstruire avansată cu întrerupere de activitate în diferite regiuni'; 
	//							        |ru = 'Advanced training with work interruption in different region");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Miss-outs (absences at work place without reasonable excuse during time, established under legislation'; 
	//                                    |ro = 'Absențe de la locul de muncă fară scuze plauzibile în conformitate cu legislația'; 
	//							        |ru = 'Miss-outs (absences at work place without reasonable excuse during time, established under legislation");

	//// 
	//OfficeHoursKinds.FullDescr	=  NStr ("en = 'Maternity leave (vacation because of newborn baby adoption)'; 
	//                                     |ro = 'Concediu de maternitate prenatal'; 
	//							         |ru = 'Maternity leave (vacation because of newborn baby adoption)");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Work duration during days off and nonworking days, holidays'; 
	//                                    |ro = 'Activitate în timpul zilelor libere, zilelor nelucrătoare și sărbatorilor'; 
	//							        |ru = 'Work duration during days off and nonworking days, holidays");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Dead time by employers fault'; 
	//                                    |ro = 'Inactivitate din vina angajatorului'; 
	//							        |ru = 'Dead time by employers fault");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Overtime duration'; 
	//                                    |ro = 'Ore suplimentare'; 
	//							        |ru = 'Overtime duration");

	//// T.
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Temporary disability without benefit allocation in cases, covered to legislation'; 
	//                                    |ro = 'Incapacitate temporară de muncă, fără alocare de beneficii in unele cazuri prevăzute de legislație'; 
	//							        |ru = 'Temporary disability without benefit allocation in cases, covered to legislation");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional vacation because of studies with employees average earnings saving,combining work and studies'; 
	//                                    |ro = 'Concediu de studiu plătit în care se îmbina munca cu studiul'; 
	//							        |ru = 'Additional vacation because of studies with employees average earnings saving,combining work and studies");

	//// 
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Additional vacation because of studies without wages maintanance'; 
	//                                    |ro = 'Concediu de studiu neplătit'; 
	//							        |ru = 'Additional vacation because of studies without wages maintanance");

	//// I.
	//OfficeHoursKinds.FullDescr	= NStr ("en = 'Work duration in day time'; 
	//                                    |ro = 'Activitate normală pe timp de zi'; 
	//							        |ru = 'Work duration in day time");

	
	
EndProcedure

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
