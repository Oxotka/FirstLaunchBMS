///////////////////////////////////////////////////////////////////////////////////////
// The procedure consists of two parts:
// 1. PredefinedDataAtServer
// In this procedure execute the filling of taxes, VAT rates, currencies and classifier working time.
// Also in this procedure is forming information about company.
// This information will be show user and will can changed.
// 2. CreateCompany
// In this procedure execute filling Predefined company, create PettyCash and prices kind.
// 

////////////////////////////////////////////////////
// Function start filling data for choisen country
// 1. Fill in tax types 
// 2. Fill in currency 
// 3. Fill in VAT rates. 
// 4. Fill in classifier of the working time use.
// 5. Fill in description of company.
// Parameters:
//  - Postfix - string - Symbol of the country, for example Ru - Russia, Ro - Romania.
//
Function PredefinedDataAtServer(Postfix) Export
	
	Structure = New Structure;
	Postfix   = Upper(Postfix);
	
	PredefinedDateAtServerForCountry(Structure, Postfix);
	
	Return Structure;
	
EndFunction

////////////////////////////////////////////////////
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

Procedure PredefinedDateAtServerForCountry(Structure, Postfix)
	
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
	
EndProcedure	// FillTaxTypesDefault()

Procedure FillCurrencyDefault(Structure)
	
	// Fill in currencies
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	//RONRef = InfobaseUpdateSB.FindCreateCurrency("946", "RON", "Leu romanesc", "RON, RON, RON, м, ban, bani, bani, м, 2");
	//RURRef = InfobaseUpdateSB.FindCreateCurrency("643", "rub.", "Russian ruble", "ruble, ruble, rubles, M, kopek, kopek, kopeks, F, 2");
	//MDLRef = InfobaseUpdateSB.FindCreateCurrency("498", "MDL", "Leu moldovenesc", "leu, lei, lei, M, ban, bani, bani, M, 2");
	//HUFRef = InfobaseUpdateSB.FindCreateCurrency("348", "HUF", "Hungarian Forint", "forint, forint, forint, M, , , , м, 2");
	
	CurrencyRef = EURRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
	Constants.FunctionalCurrencyTransactionsAccounting.Set(False);
	
	Structure.Insert("Currency", CurrencyRef);
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), (10882 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	
EndProcedure	// FillCurrencyDefault()

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
	
	MapClassifierOfWorkingTimeUsage = New Map;
	
	// B.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.Disease, "Temporary incapacity to labor with benefit assignment according to the law");
	
	// V.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.WeekEnd, "Weekends (weekly leave) and public holidays");
	
	// VP.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault, "Dead time by the employees fault");
	
	// VCH.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.WorkEveningClock, "Working hours in the evenings");
	
	// G.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.PublicResponsibilities, "Absenteeism at the time of state or public duties according to the law");
	
	// DB.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation, "Annual additional leave without salary");
	
	// TO.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission, "Leave without pay provided to employee with employer permission");
	
	// ZB.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.Strike, "Strike (in conditions and order provided by legislation)");
	
	// TO.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.BusinessTrip, "Business trip");
	
	// N.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.WorkNightHours, "Working hours at night time");
	
	// NB.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments, "Suspension from work (disqualification) as required by the Law, without payroll");
	
	// NV.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid, "Additional days off (without salary)");
	
	// NZ.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.SalaryPayoffDelay, "Suspension of work in case of delayed salary");
	
	// NN.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons, "Unjustified absence from work (until the circumstances are clarified)");
	
	// NO.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment, "Suspension from work (disqualification) with payment (benefit) according to the law");
	
	// NP.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.Simple, "Downtime due to reasons regardless of the employer and the employee");
	
	// OV.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid, "Additional days-off (paid)");
	
	// OD.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.AdditionalVacation, "Annual additional paid leave");
	
	// OZH.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.VacationByCareForBaby, "Maternity leave up to the age of three");
	
	// OZ.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation, "Leave without pay in cases provided by law");
	
	// OT.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.MainVacation, "Annual paid leave");
	
	// PV.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.ForcedTruancy, "Time of the forced absenteeism in case of the dismissal recognition, transition to another work place or dismissal from work with reemployment on the former one");
	
	// PK.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.QualificationRaise, "On-the-job further training");
	
	// PM.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain, "Further training off-the-job in other area");
	
	// PR.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.Truancies, "Absenteeism (absence from work place without valid reasons within the time fixed by the law)");
	
	// R.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth, "Maternity leave (vacation because of newborn baby adoption)");
	
	// RV.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.Holidays, "Working hours at weekends and non-work days, holidays");
	
	// RP.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.DowntimeByEmployerFault, "Dead time by employers fault");
	
	// C.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.Overtime, "Overtime duration");
	
	// T.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.DiseaseWithoutPay, "Temporary incapacity to labor without benefit assignment in cases provided by the law");
	
	// Y.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.VacationForTraining, "Additional leave due to training with an average pay, combining work and training");
	
	// YD.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid, "Additional leave because of the training without salary");
	
	// I.
	MapClassifierOfWorkingTimeUsage.Insert(Catalogs.WorkingHoursKinds.Work, "Working hours in the daytime");
	
	
	FillClassifierOfWorkingTimeUsageFormMap(MapClassifierOfWorkingTimeUsage);
	
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
// EndRegion Default


//      В КАЖДОЙ СТРАНЕ - СВОЯ ПЯТИДНЕВКА ?


#Region Ru

Procedure FillTaxTypesRu()
	
	ArrayOfTaxTypes = New Array;
	
	ArrayOfTaxTypes.Add(NewTaxType("НДС"));
	ArrayOfTaxTypes.Add(NewTaxType("Налог на прибыль"));
	
	FillTaxTypesFromArray(ArrayOfTaxTypes);
	
EndProcedure	// FillTaxTypesRu()

Procedure FillCurrencyRu(Structure)
	
	// Fill in currencies.
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	RURRef = InfobaseUpdateSB.FindCreateCurrency("643", "rub.", "Russian ruble", "ruble, ruble, rubles, M, kopek, kopek, kopeks, F, 2");
	
	CurrencyRef = RURRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
	// Если требуется, чтобы "Валюта Оперативного Учета" была отлична от "Национальной Валюты" - 
	// - нужно, чтобы на "Форме Первоначального Заполнения" отображался блок с валютами - 
	// - следует включить эту опцию
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	Structure.Insert("Currency", CurrencyRef);
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), (343139 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	StructureCurrencyRate = NewStructureCurrencyRate(EURRef, Date("20140524"), (468350 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	
EndProcedure	// FillCurrencyRu()

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
	
EndProcedure	// FillVATRatesRu()

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
	
EndProcedure	//	FillClassifierOfWorkingTimeUsageRu()

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
	
EndProcedure	//	FillInformationAboutNewCompanyRu()

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
	
EndProcedure	// FillTaxTypesRo()

Procedure FillCurrencyRo(Structure)
	
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	RONRef = InfobaseUpdateSB.FindCreateCurrency("946", "RON", "Leu romanesc", "RON, RON, RON, м, ban, bani, bani, м, 2");

	CurrencyRef = RONRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
	// Если требуется, чтобы "Валюта Оперативного Учета" была отлична от "Национальной Валюты" - 
	// - нужно, чтобы на "Форме Первоначального Заполнения" отображался блок с валютами - 
	// - следует включить эту опцию
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	
	Structure.Insert("Currency", CurrencyRef);
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), (32410 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	StructureCurrencyRate = NewStructureCurrencyRate(EURRef, Date("20140524"), (44164 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	
EndProcedure	// FillCurrencyRo()

Procedure FillVATRatesRo(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("Cota TVA 20%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT", VATRateDefault);
		Return;
	EndIf;
	
	ArrayOfVATRates = New Array;
	
	//VATRate.Description = NStr("en='VAT rate 20%';ro='';ru='Ставка НДС 20%'");
	ArrayOfVATRates.Add(NewVATRate("Cota TVA 20%", 20));
	
	//VATRate.Description = NStr("en='VAT rate 20% w/o offset right';ro='Cota TVA 20% fara drept de deducere';ru='Ставка НДС 20% без права зачета'");
	ArrayOfVATRates.Add(NewVATRate("Cota TVA 20% fara drept de deducere", 20));	
	
	//VATRate.Description = NStr("en='Reversed VAT 20%';ro='Taxare inversă cu cota TVA 20%';ru='Взаимозачет со ставкой НДС 20%'");
	ArrayOfVATRates.Add(NewVATRate("Taxare inversă cu cota TVA  20%", 0));	
	
	//VATRate.Description = NStr("en='Reversed VAT, intangibles 20%';ro='Taxare inversă servicii intangibile cu cota TVA 20%';ru='Взаимозачет со ставкой НДС 20% (intangibile)'");
	ArrayOfVATRates.Add(NewVATRate("Taxare inversă servicii intangibile cu cota TVA 20%", 0));	
	
	//VATRate.Description = NStr("en='Import VAT from EU 20%';ro='TVA la Import din UE cu cota TVA 20%';ru='НДС на импорт из ЕС со ставкой 20%'");
	ArrayOfVATRates.Add(NewVATRate("TVA la Import din UE cu cota TVA 20%", 0));	
	
	//VATRate.Description = NStr("en='VAT rate 5%';ro='Cota TVA 5%';ru='Ставка НДС 5%'");
	ArrayOfVATRates.Add(NewVATRate("5%", 5));	
	
	//VATRate.Description = NStr("en='VAT rate 5% w/o offset right';ro='Cota TVA 5% fara drept de deducere';ru='Ставка НДС 5% без права зачета'");
	ArrayOfVATRates.Add(NewVATRate("Cota TVA 5% fara drept de deducere", 5));	
	
	//VATRate.Description = NStr("en='VAT rate 9%';ro='Cota TVA 9%';ru='Ставка НДС 9%'");
	ArrayOfVATRates.Add(NewVATRate("9%", 9));	
	
	//VATRate.Description = NStr("en='VAT rate 9% w/o offset right';ro='Cota TVA 9% fara drept de deducere';ru='Ставка НДС 9% без права зачета'");
	ArrayOfVATRates.Add(NewVATRate("Cota TVA 9% fara drept de deducere", 9));	
	
	//VATRate.Description = NStr("en='Non-taxable';ro='TVA Neimpozabile';ru='НДС Необлагаемый'");
	ArrayOfVATRates.Add(NewVATRate("TVA Neimpozabile", 0));	
	
	//VATRate.Description = NStr("en='Non-taxable EU';ro='TVA Neimpozabile EU';ru='НДС Необлагаемый ЕС'");
	ArrayOfVATRates.Add(NewVATRate("TVA NeimpozabileEU - Neimpozabile la import din UE destinate revănzării", 0));	
	
	//VATRate.Description = NStr("en='VAT exempt w/offset right';ro='Scutite cu drept de deducere';ru='Освобожденные с правом зачета'");
	ArrayOfVATRates.Add(NewVATRate("Scutite cu drept de deducere", 0));	
	
	//VATRate.Description = NStr("en='VAT exempt w/o offset right';ro='Scutite fara drept de deducere';ru='Освобожденные без права зачета'");
	ArrayOfVATRates.Add(NewVATRate("Scutite fara drept de deducere", 0));	
	
	//VATRate.Description = NStr("en='Export VAT exempt w offset right';ro='Scutite la Export cu drept de deducere';ru='Освобожденные на экспорт с правом зачета'");
	ArrayOfVATRates.Add(NewVATRate("Scutite la Export cu drept de deducere", 0));	
	
	//VATRate.Description = NStr("en='Export VAT exempt w offset right - § C, D';ro='Scutite la Export cu drept de deducere conf. art.143 alin.1 lit.c) și d)';ru='Освобожденные на экспорт с правом зачета согласно п.143 § C, D'");
	ArrayOfVATRates.Add(NewVATRate("Scutite la Export cu drept de deducere conf. art.143 alin.1 lit.c) și d)", 0));	
	
	//VATRate.Description = NStr("en='Export VAT exempt w/o offset right';ro='Scutite la Export fără drept de deducere';ru='Освобожденные на экспорт без права зачета'");
	ArrayOfVATRates.Add(NewVATRate("Scutite la Export fără drept de deducere", 0));	
	
	//VATRate.Description = NStr("en='Export VAT exempt w offset right (EU)- § A, D';ro='Scutite la Export in UE conf. art.143 alin.2 lit.a) și d)';ru='Освобожденные на экспортв ЕС с правом зачета согласно п.143 § A, D'");
	ArrayOfVATRates.Add(NewVATRate("Scutite la Export in UE conf. art.143 alin.2 lit.a) și d)", 0));	
	
	//VATRate.Description = NStr("en='Export VAT exempt w offset right (EU) § B, C';ro='Scutite la Export in UE conf. art.143 alin.2 lit.b) și c)';ru='Освобожденные на экспорт с правом зачета согласно п.143 § B, C'");
	ArrayOfVATRates.Add(NewVATRate("Scutite la Export in UE conf. art.143 alin.2 lit.b) și c)", 0));	
	
	//VATRate.Description = NStr("en='Import from EU VAT exempt, to resell';ro='Scutite la Import din UE destinate revănzării';ru='Освобожденный импорт из ЕС с целью перепродажи'");
	ArrayOfVATRates.Add(NewVATRate("Scutite la Import din UE destinate revănzării", 0));	
	
	//VATRate.Description = NStr("en='Import from EU VAT exempt, internal use';ro='Scutite la Import din UE pentru nevoile firmei';ru='Освобожденный импорт из ЕС для внутр.использования'");
	ArrayOfVATRates.Add(NewVATRate("Scutite la Import din UE pentru nevoile firmei", 0));	
	
	FillVATRateFormArray(ArrayOfVATRates);
	
	Structure.Insert("VAT", Catalogs.VATRates.FindByDescription("Cota TVA 20%"));
	
EndProcedure	// FillVATRatesRo()

Procedure FillClassifierOfWorkingTimeUsageRo()
	
	// ....
	MapClassifierOfWorkingTimeUsage = New Map;
	
	// B.
    // "Temporary disability with benefit allocation according to legislation" 
	// "Временная нетрудоспособность с назначением пособия согласно законодательству");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Disease, "Incapacitate temporară de muncă cu alocare de beneficii în conformitate cu legislația"); 
	
	// V.
    // "Days off (weekly vacation) and nonworking holidays" 
	// "Выходные дни (еженедельный отпуск) и  нерабочие праздничные дни");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WeekEnd, "Zile libere (vacanța săptămânală) și vacanțe nelucrătoare"); 
		
	// VP.
    // "Dead time by the employees fault" 
	// "Простои по вине работника");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault, "Timp pierdut din vina angajaților"); 
	
	// VCH.
    // "Work duration in afternoon time" 
	// "Продолжительность работы в вечернее время");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkEveningClock, "Activitate normală după-amiaza"); 
	
	// G.
    // "Unjustified absence during state or social duties according to legislation" 
	// "Невыходы на время исполнения государственных или общественных обязанностей согласно законодательству");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.PublicResponsibilities, "Absența nejustificată în timpul datoriilor sociale sau de stat în conformitate cu legislația"); 

	// DB.
    // "Annual additional vacation without wage maintenance" 
	// "Ежегодный дополнительный отпуск без сохранения заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation, "Vacanță anuală suplimentară neplătită"); 
		
	// TO.
    // "Vacation without wage maintanance, given to the employee by the employers permission" 
	// "Отпуск без сохранения заработной платы, предоставляемый работнику по разрешению работодателя");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission, "Vacanță neplătită a angajatului cu permisiunea angajatorului"); 
	
	// ZB.
    // "Strike (in conditions and order, provided by legislation)" 
	// "Забастовка (при условиях и в порядке, предусмотренных законом)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Strike, "Greva (in condițiile prevazute de lege)"); 
	
	// TO.
    // "Service BusinessTrip" 
	// "Рабочая командировка");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.BusinessTrip, "Deplasări în interes de serviciu"); 
	
	// N.
    // "Duration works In night Time" 
	// "Продолжительность работы в ночное время");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkNightHours, "Activitate pe timp de noapte"); 
	
	// NB.
    // "Dismissal from work (exclusion from work) by reasons, covered by legislation, without wage charging" 
	// "Отстранение от работы (недопущение к работе) по причинам, предусмотренным законодательством, без начисления заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments, "Concedierea de la locul de muncă ( excludere de la locul de muncă ) din motive , acceptate de legislație , fără plata salariului"); 
	
	// NV.
    // "Additional days off (without wage maintanance)" 
	// "Дополнительные выходные дни (без сохранения заработной платы)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid, "Zile libere suplimentare neplătite"); 
	
	// NZ.
    // "Time of work interruption in case of wages payout delay" 
	// "Время приостановки работы в случае задержки выплаты заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.SalaryPayoffDelay, "Întreruperea activității datorită înârzierii plații salariale"); 
	
	// NN.
    // "Absence by the unclarified reasons (before clarifying reasons)" 
	// "Неявки по невыясненным причинам (до выяснения обстоятельств)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons, "Absentarea de la locul de muncă din motive nespecificate (sau înainte de clarificarea lor)"); 
	
	// NO.
    // "Dismissal from work (exclusion from work) with payouts (aid) according to legislation" 
	// "Отстранение от работы (недопущение к работе) с оплатой (пособием) в соответствии с законодательством");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment, "Concedierea de la locul de muncă ( de excludere de la locul de muncă ) cu plată ( ajutor ) în conformitate cu legislația"); 
	
	// NP.
    // "Dead time by reasons, not depending on employer and employee" 
	// "Время простоя по причинам, не зависящим от работодателя и работника");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Simple, "Inactivitatea angajaților din motive ce nu depind de angajat sau angajator"); 
	
	// OV.
    // "Additional days off (payable)" 
	// "Дополнительные выходные дни (оплачиваемые)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid, "Zile libere suplimentare plătite"); 
	
	// OD.
    // "Annual Additional Paid vacation" 
	// "Ежегодный дополнительный оплачиваемый отпуск");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalVacation, "Concediu anual suplimentar plătit"); 
	
	// OZH.
    // "Baby-sitting vacation before his three year old attainment" 
	// "Отпуск по уходу за ребенком до достижения им возраста трех лет");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByCareForBaby, "Concediu de maternitate postnatal"); 
	
	// OZ.
    // "Vacation without wage maintanance in cases, covered by legislation" 
	// "Отпуск без сохранения заработной платы в случаях, предусмотренных законодательством");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation, "Concediu neplătit în cazurile reglementate de legislație"); 
	
	// OT.
    // "Main annual payable vacation" 
	// "Ежегодный основной оплачиваемый отпуск");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.MainVacation, "Concediu anual plătit"); 
	
	// PV.
    // "Time of forced abcense in case of dismissal acknowledgment, remittance or deletion of work by illegal with reinstatement" 
	// "Время вынужденного прогула в случае признания увольнения, перевода на другую работу или отстранения от работы незаконными с восстановлением на прежней работе");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.ForcedTruancy, "Încetarea temporară a activității"); 
	
	// PK.
    // "Advanced training with work interruption" 
	// "Повышение квалификации с отрывом от работы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaise, "Intstruire avansată cu întrerupere de activitate"); 
	
	// PM.
    // "Advanced training with work interruption in different region" 
	// "Повышение квалификации с отрывом от работы в другой местности");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain, "Intstruire avansată cu întrerupere de activitate în diferite regiuni"); 
	
	// PR.
    // "Miss-outs (absences at work place without reasonable excuse during time, established under legislation" 
	// "Прогулы (отсутствие на рабочем месте без уважительных причин в течение времени, установленного законодательством)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Truancies, "Absențe de la locul de muncă fară scuze plauzibile în conformitate cu legislația"); 
	
	// R.
    // "Maternity leave (vacation because of newborn baby adoption)" 
	// "Отпуск по беременности и родам (отпуск в связи с усыновлением новорожденного ребенка)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth, "Concediu de maternitate prenatal"); 
	
	// RV.
    // "Work duration during days off and nonworking days, holidays" 
	// "Продолжительность работы в выходные и нерабочие, праздничные дни");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Holidays, "Activitate în timpul zilelor libere, zilelor nelucrătoare și sărbatorilor"); 
	
	// RP.
    // "Dead time by employers fault" 
	// "Время простоя по вине работодателя");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployerFault, "Inactivitate din vina angajatorului"); 
	
	// C.
    // "Overtime duration" 
	// "Продолжительность сверхурочной работы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Overtime, "Ore suplimentare"); 
	
	// T.
    // "Temporary disability without benefit allocation in cases, covered to legislation" 
	// "Временная нетрудоспособность без назначения пособия в случаях, предусмотренных законодательством");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DiseaseWithoutPay, "Incapacitate temporară de muncă, fără alocare de beneficii in unele cazuri prevăzute de legislație"); 
	
	// Y.
    // "Additional vacation because of studies with employees average earnings saving,combining work and studies" 
	// "Дополнительный отпуск в связи с обучением с сохранением среднего заработка работникам, совмещающим работу с обучением");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTraining, "Concediu de studiu plătit în care se îmbina munca cu studiul"); 
	
	// YD.
    // "Additional vacation because of studies without wages maintanance" 
	// "Дополнительный отпуск в связи с обучением без сохранения заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid, "Concediu de studiu neplătit"); 
	
	// I.
    // "Work duration in day time" 
	// "Продолжительность работы в дневное время");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Work, "Activitate normală pe timp de zi"); 
		
		
	FillClassifierOfWorkingTimeUsageFormMap(MapClassifierOfWorkingTimeUsage);
	
EndProcedure	// FillClassifierOfWorkingTimeUsageRo()

Procedure FillInformationAboutNewCompanyRo(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", "Firma Noastra SRL");
	StructureCompany.Insert("Prefix", "FN-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", False);
	
	// Касса создается в CreateCompany(), потому что сейчас мы не знаем валюту учета.
	// В данный момент зададим имя основной кассы.
	StructureCompany.Insert("NameOfPettyCash", "Casa Principala");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure	// FillInformationAboutNewCompanyRo()


#EndRegion    
// EndRegion RO

#Region Lv

Procedure FillTaxTypesLv()
	
	ArrayOfTaxTypes = New Array;
	ArrayOfTaxTypes.Add(NewTaxType("PVN"));
	ArrayOfTaxTypes.Add(NewTaxType(""));
	
	FillTaxTypesFromArray(ArrayOfTaxTypes);
	
EndProcedure	// FillTaxTypesLv()

Procedure FillCurrencyLv(Structure)
	
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	
	CurrencyRef = EURRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// If it necessary to keep accounts of operations in several currencies, 
	// you should enable this option
	// Если требуется, чтобы "Валюта Оперативного Учета" была отлична от "Национальной Валюты" - 
	// - нужно, чтобы на "Форме Первоначального Заполнения" отображался блок с валютами - 
	// - следует включить эту опцию
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	Structure.Insert("Currency", CurrencyRef);
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), (10882 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);

EndProcedure	// FillCurrencyLv()

Procedure FillVATRatesLv(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("21%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	ArrayOfVATRates = New Array;
	ArrayOfVATRates.Add(NewVATRate("21%", 21));
	ArrayOfVATRates.Add(NewVATRate("0%", 0));
	ArrayOfVATRates.Add(NewVATRate("Bez PVN", 0));
	
	FillVATRateFormArray(ArrayOfVATRates);
	
	Structure.Insert("VAT", Catalogs.VATRates.FindByDescription("21%"));
	
EndProcedure	// FillVATRatesLv()

Procedure FillClassifierOfWorkingTimeUsageLv()
	
	MapClassifierOfWorkingTimeUsage = New Map;
	// B.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Disease,
		"Darbnespēja ar pabalstu");
	// V.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WeekEnd,
		"Brīvdienas un svētku dienas");
	// VP.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault,
		"Dīkstāve pēc darbinieka vainas");
	
	// VCH.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkEveningClock,
		"Vakara stundas");
	
	// G.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.PublicResponsibilities,
		"Neierašanās darbā valsts vai sabiedrības pienākumu pildīšanas laikā");

	// DB.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation,
		"Ikgadējais papildatvaļinājums bez darba algas saglabāšanas");
		
	// TO.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission,
		"Atvaļinājums bez darba algas saglabāšanas pēc vienošanas ar darba devēju");
	
	// ZB.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Strike,
		"Streiks pēc streika norises kartībām");
	
	// TO.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.BusinessTrip,
		"Komandējums");
	
	// N.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkNightHours,
		"Nakts stundas");
	
	// NB.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments,
		"Atstādināšana no darba bez darba algas saglabašanas");
	
	// NV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid,
		"Papildbrīvdienas bez darba algas saglabašanas");
	
	// NZ.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.SalaryPayoffDelay,
		"Darba partraukums algas izmaksas aizkavējuma deļ");
	
	// NN.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons,
		"Kavējumi bez attaisņojuma dokumentiem");
	
	// NO.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment,
		"Atstādināšana no darba ar pabalstu");
	
	// NP.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Simple,
		"Dīkstāve pēc neatkarīgiem no darba devēja un darbinieka iemesliem");
	
	// OV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid,
		"Papildbrīvdienas apmaksājamās");
	
	// OD.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalVacation,
		"Ikgadējais papildatvaļinājums");
	
	// OZH.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByCareForBaby,
		"Bērna kopsanas atvaļinājums");
	
	// OZ.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation,
		"Atvaļinājums bez darba algas saglabāsanas saskaņā ar likumdošanu");
	
	// OT.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.MainVacation,
		"Ikgadējais apmaksātais atvaļinājums");
	
	// PV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.ForcedTruancy,
		"Darba piespiedu kavējuma laiks");
	
	// PK.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaise,
		"Kvalifikācijas paaugstināšana ar darba pārtraukumu");
	
	// PM.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain,
		"Kvalifikācijas paaugstināšana ar darba pārtraukumu citā apvidū");
	
	// PR.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Truancies,
		"Darba kavējums bez attaisnojošiem iemesliem");
	
	// R.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth,
		"Grūtniecības un dzemdību atvaļinājums");
	
	// RV.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Holidays,
		"Brīvdienas un svētku dienas");
	
	// RP.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployerFault,
		"Dīkstāve pēc darba devēja vainas");
	
	// C.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Overtime,
		"Virsstundas");
	
	// T.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DiseaseWithoutPay,
		"Darbnespēja bez pabalsta");
	
	// Y.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTraining,
		"Apmaksāts mācību papildatvaļinājums");
	
	// YD.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid,
		"Mācību papildatvaļinājums bez darba algas saglabašanas");
	
	// I.
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Work,
		"Darba diena");
		
	FillClassifierOfWorkingTimeUsageFormMap(MapClassifierOfWorkingTimeUsage);
	
EndProcedure	// FillClassifierOfWorkingTimeUsageLv()

Procedure FillInformationAboutNewCompanyLv(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", "SIA ""Mūsu kompānija""");
	StructureCompany.Insert("Prefix", "MK-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", True);
	
	// Касса создается в CreateCompany(), потому что сейчас мы не знаем валюту учета.
	// В данный момент зададим имя основной кассы.
	StructureCompany.Insert("NameOfPettyCash", "Galvenā kase");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure	// FillInformationAboutNewCompanyLv()

#EndRegion
// EndRegion LV

#Region Hu

Procedure FillTaxTypesHu()
	
	ArrayOfTaxTypes = New Array;
	ArrayOfTaxTypes.Add(NewTaxType("ÁFA"));
	ArrayOfTaxTypes.Add(NewTaxType("Nyereségadó"));
	
	FillTaxTypesFromArray(ArrayOfTaxTypes);
	
EndProcedure	// FillTaxTypesHu()

Procedure FillCurrencyHu(Structure)
	
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	HUFRef = InfobaseUpdateSB.FindCreateCurrency("348", "HUF", "Hungarian Forint", "forint, forint, forint, M, , , , м, 2");
	
	CurrencyRef = HUFRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// Если используется несколько валют, то следует включить эту опцию, чтобы отображался блок с валютами.
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	Structure.Insert("Currency", CurrencyRef);
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), (22250 / 100));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	StructureCurrencyRate = NewStructureCurrencyRate(EURRef, Date("20140524"), (30304 / 100));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	
EndProcedure	// FillCurrencyHu()

Procedure FillVATRatesHu(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("27%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	ArrayOfVATRates = New Array;
	ArrayOfVATRates.Add(NewVATRate("5%", 5));
	//ArrayOfVATRates.Add(NewVATRate("18% / 118%", 18, True));
	//ArrayOfVATRates.Add(NewVATRate("10% / 110%", 10, True));
	ArrayOfVATRates.Add(NewVATRate("0%", 0));
	//ArrayOfVATRates.Add(NewVATRate("Без НДС", 0,,True));
	ArrayOfVATRates.Add(NewVATRate("18%", 18));
	
	FillVATRateFormArray(ArrayOfVATRates);
	
	Structure.Insert("VAT", Catalogs.VATRates.FindByDescription("27%"));
	
EndProcedure	// FillVATRatesHu()

Procedure FillClassifierOfWorkingTimeUsageHu()
	
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
	
EndProcedure	// FillClassifierOfWorkingTimeUsageHu()

Procedure FillInformationAboutNewCompanyHu(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", """Cégünk"" KFT");
	StructureCompany.Insert("Prefix", "CG-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", True);
	
	// Касса создается в CreateCompany(), потому что сейчас мы не знаем валюту учета.
	// В данный момент зададим имя основной кассы.
	StructureCompany.Insert("NameOfPettyCash", "Főpénztár");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure	// FillInformationAboutNewCompanyHu()

#EndRegion
// EndRegion HU

#Region Md

Procedure FillTaxTypesMd()
	
	ArrayOfTaxTypes = New Array;
	ArrayOfTaxTypes.Add(NewTaxType("TVA"));
	ArrayOfTaxTypes.Add(NewTaxType("Impozit pe venit"));
	
	FillTaxTypesFromArray(ArrayOfTaxTypes);
	
EndProcedure	// FillTaxTypesMd()

Procedure FillCurrencyMd(Structure)
	
	USDRef = InfobaseUpdateSB.FindCreateCurrency("840", "USD", "US Dollar", "USD, USD, USD, м, cent, cents, cents, м, 2");
	EURRef = InfobaseUpdateSB.FindCreateCurrency("978", "EUR", "Euro", "EUR, EUR, EUR, м, euro cent, euro cents, euro cents, м, 2");
	MDLRef = InfobaseUpdateSB.FindCreateCurrency("498", "MDL", "Leu moldovenesc", "leu, lei, lei, M, ban, bani, bani, M, 2");
	
	CurrencyRef = MDLRef;
	Constants.AccountingCurrency.Set(CurrencyRef);
	Constants.NationalCurrency.Set(CurrencyRef);
	
	// Если используется несколько валют, то следует включить эту опцию, чтобы отображался блок с валютами.
	Constants.FunctionalCurrencyTransactionsAccounting.Set(True);
	Structure.Insert("Currency", CurrencyRef);
	
	// Filling currency rates
	StructureCurrencyRate = NewStructureCurrencyRate(USDRef, Date("20140524"), (138339 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	StructureCurrencyRate = NewStructureCurrencyRate(EURRef, Date("20140524"), (189171 / 10000));
	FillCurrencyRatesFromStructure(StructureCurrencyRate);
	
EndProcedure	// FillCurrencyMd()

Procedure FillVATRatesMd(Structure)
	
	VATRateDefault = Catalogs.VATRates.FindByDescription("20%");
	If ValueIsFilled(VATRateDefault) Then
		Structure.Insert("VAT",VATRateDefault);
		Return;
	EndIf;
	
	ArrayOfVATRates = New Array;
	ArrayOfVATRates.Add(NewVATRate("Fără TVA", 0,,True));
	ArrayOfVATRates.Add(NewVATRate("0%", 0));
	ArrayOfVATRates.Add(NewVATRate("6%", 6, True));
	ArrayOfVATRates.Add(NewVATRate("8%", 8, True));
	ArrayOfVATRates.Add(NewVATRate("20%", 20));
	
	FillVATRateFormArray(ArrayOfVATRates);
	
	Structure.Insert("VAT", Catalogs.VATRates.FindByDescription("20%"));
	
EndProcedure	// FillVATRatesMd()

Procedure FillClassifierOfWorkingTimeUsageMd()
	
	// ....
	MapClassifierOfWorkingTimeUsage = New Map;
	
	// B.
    // "Temporary disability with benefit allocation according to legislation" 
	// "Временная нетрудоспособность с назначением пособия согласно законодательству");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Disease, "Incapacitate temporară de muncă cu alocare de beneficii în conformitate cu legislația"); 
	
	// V.
    // "Days off (weekly vacation) and nonworking holidays" 
	// "Выходные дни (еженедельный отпуск) и  нерабочие праздничные дни");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WeekEnd, "Zile libere (vacanța săptămânală) și vacanțe nelucrătoare"); 
		
	// VP.
    // "Dead time by the employees fault" 
	// "Простои по вине работника");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployeeFault, "Timp pierdut din vina angajaților"); 
	
	// VCH.
    // "Work duration in afternoon time" 
	// "Продолжительность работы в вечернее время");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkEveningClock, "Activitate normală după-amiaza"); 
	
	// G.
    // "Unjustified absence during state or social duties according to legislation" 
	// "Невыходы на время исполнения государственных или общественных обязанностей согласно законодательству");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.PublicResponsibilities, "Absența nejustificată în timpul datoriilor sociale sau de stat în conformitate cu legislația"); 

	// DB.
    // "Annual additional vacation without wage maintenance" 
	// "Ежегодный дополнительный отпуск без сохранения заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidAdditionalVacation, "Vacanță anuală suplimentară neplătită"); 
		
	// TO.
    // "Vacation without wage maintanance, given to the employee by the employers permission" 
	// "Отпуск без сохранения заработной платы, предоставляемый работнику по разрешению работодателя");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByEmployerPermission, "Vacanță neplătită a angajatului cu permisiunea angajatorului"); 
	
	// ZB.
    // "Strike (in conditions and order, provided by legislation)" 
	// "Забастовка (при условиях и в порядке, предусмотренных законом)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Strike, "Greva (in condițiile prevazute de lege)"); 
	
	// TO.
    // "Service BusinessTrip" 
	// "Рабочая командировка");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.BusinessTrip, "Deplasări în interes de serviciu"); 
	
	// N.
    // "Duration works In night Time" 
	// "Продолжительность работы в ночное время");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.WorkNightHours, "Activitate pe timp de noapte"); 
	
	// NB.
    // "Dismissal from work (exclusion from work) by reasons, covered by legislation, without wage charging" 
	// "Отстранение от работы (недопущение к работе) по причинам, предусмотренным законодательством, без начисления заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromWorkWithoutPayments, "Concedierea de la locul de muncă ( excludere de la locul de muncă ) din motive , acceptate de legislație , fără plata salariului"); 
	
	// NV.
    // "Additional days off (without wage maintanance)" 
	// "Дополнительные выходные дни (без сохранения заработной платы)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysNotPaid, "Zile libere suplimentare neplătite"); 
	
	// NZ.
    // "Time of work interruption in case of wages payout delay" 
	// "Время приостановки работы в случае задержки выплаты заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.SalaryPayoffDelay, "Întreruperea activității datorită înârzierii plații salariale"); 
	
	// NN.
    // "Absence by the unclarified reasons (before clarifying reasons)" 
	// "Неявки по невыясненным причинам (до выяснения обстоятельств)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.NotAppearsByUnknownReasons, "Absentarea de la locul de muncă din motive nespecificate (sau înainte de clarificarea lor)"); 
	
	// NO.
    // "Dismissal from work (exclusion from work) with payouts (aid) according to legislation" 
	// "Отстранение от работы (недопущение к работе) с оплатой (пособием) в соответствии с законодательством");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.RemovalFromJobsWithPayment, "Concedierea de la locul de muncă ( de excludere de la locul de muncă ) cu plată ( ajutor ) în conformitate cu legislația"); 
	
	// NP.
    // "Dead time by reasons, not depending on employer and employee" 
	// "Время простоя по причинам, не зависящим от работодателя и работника");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Simple, "Inactivitatea angajaților din motive ce nu depind de angajat sau angajator"); 
	
	// OV.
    // "Additional days off (payable)" 
	// "Дополнительные выходные дни (оплачиваемые)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalWeekEndDaysPaid, "Zile libere suplimentare plătite"); 
	
	// OD.
    // "Annual Additional Paid vacation" 
	// "Ежегодный дополнительный оплачиваемый отпуск");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.AdditionalVacation, "Concediu anual suplimentar plătit"); 
	
	// OZH.
    // "Baby-sitting vacation before his three year old attainment" 
	// "Отпуск по уходу за ребенком до достижения им возраста трех лет");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByCareForBaby, "Concediu de maternitate postnatal"); 
	
	// OZ.
    // "Vacation without wage maintanance in cases, covered by legislation" 
	// "Отпуск без сохранения заработной платы в случаях, предусмотренных законодательством");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.UnpaidVacationByLegislation, "Concediu neplătit în cazurile reglementate de legislație"); 
	
	// OT.
    // "Main annual payable vacation" 
	// "Ежегодный основной оплачиваемый отпуск");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.MainVacation, "Concediu anual plătit"); 
	
	// PV.
    // "Time of forced abcense in case of dismissal acknowledgment, remittance or deletion of work by illegal with reinstatement" 
	// "Время вынужденного прогула в случае признания увольнения, перевода на другую работу или отстранения от работы незаконными с восстановлением на прежней работе");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.ForcedTruancy, "Încetarea temporară a activității"); 
	
	// PK.
    // "Advanced training with work interruption" 
	// "Повышение квалификации с отрывом от работы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaise, "Intstruire avansată cu întrerupere de activitate"); 
	
	// PM.
    // "Advanced training with work interruption in different region" 
	// "Повышение квалификации с отрывом от работы в другой местности");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.QualificationRaiseInAnotherTerrain, "Intstruire avansată cu întrerupere de activitate în diferite regiuni"); 
	
	// PR.
    // "Miss-outs (absences at work place without reasonable excuse during time, established under legislation" 
	// "Прогулы (отсутствие на рабочем месте без уважительных причин в течение времени, установленного законодательством)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Truancies, "Absențe de la locul de muncă fară scuze plauzibile în conformitate cu legislația"); 
	
	// R.
    // "Maternity leave (vacation because of newborn baby adoption)" 
	// "Отпуск по беременности и родам (отпуск в связи с усыновлением новорожденного ребенка)");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationByPregnancyAndChildbirth, "Concediu de maternitate prenatal"); 
	
	// RV.
    // "Work duration during days off and nonworking days, holidays" 
	// "Продолжительность работы в выходные и нерабочие, праздничные дни");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Holidays, "Activitate în timpul zilelor libere, zilelor nelucrătoare și sărbatorilor"); 
	
	// RP.
    // "Dead time by employers fault" 
	// "Время простоя по вине работодателя");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DowntimeByEmployerFault, "Inactivitate din vina angajatorului"); 
	
	// C.
    // "Overtime duration" 
	// "Продолжительность сверхурочной работы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Overtime, "Ore suplimentare"); 
	
	// T.
    // "Temporary disability without benefit allocation in cases, covered to legislation" 
	// "Временная нетрудоспособность без назначения пособия в случаях, предусмотренных законодательством");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.DiseaseWithoutPay, "Incapacitate temporară de muncă, fără alocare de beneficii in unele cazuri prevăzute de legislație"); 
	
	// Y.
    // "Additional vacation because of studies with employees average earnings saving,combining work and studies" 
	// "Дополнительный отпуск в связи с обучением с сохранением среднего заработка работникам, совмещающим работу с обучением");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTraining, "Concediu de studiu plătit în care se îmbina munca cu studiul"); 
	
	// YD.
    // "Additional vacation because of studies without wages maintanance" 
	// "Дополнительный отпуск в связи с обучением без сохранения заработной платы");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.VacationForTrainingUnpaid, "Concediu de studiu neplătit"); 
	
	// I.
    // "Work duration in day time" 
	// "Продолжительность работы в дневное время");
	MapClassifierOfWorkingTimeUsage.Insert(
		Catalogs.WorkingHoursKinds.Work, "Activitate normală pe timp de zi"); 
		
		
	FillClassifierOfWorkingTimeUsageFormMap(MapClassifierOfWorkingTimeUsage);
	
EndProcedure	// FillClassifierOfWorkingTimeUsageMd()

Procedure FillInformationAboutNewCompanyMd(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", "SRL ""Compania noastră""");
	StructureCompany.Insert("Prefix", "OF-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", True);
	
	// Касса создается в CreateCompany(), потому что сейчас мы не знаем валюту учета.
	// В данный момент зададим имя основной кассы.
	StructureCompany.Insert("NameOfPettyCash", "Casa principală");
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure	// FillInformationAboutNewCompanyMd(Structure)

#EndRegion
// EndRegion MD


#EndRegion
// #EndRegion ProceduresForCountry