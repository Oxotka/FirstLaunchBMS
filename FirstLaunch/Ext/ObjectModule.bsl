﻿Function PredifenedDateAtServer(Postfix) Export
	
	Structure = New Structure;
	Postfix   = Upper(Postfix);
	
	PredifenedDateAtServerForCountry(Structure, Postfix);
	
	Return Structure;
	
EndFunction

Procedure CreateCompany(Structure) Export
	
	// Fill petty cashes.
	PettyCash = Catalogs.TaxTypes.FindByDescription("Main petty cash");
	If Not ValueIsFilled(PettyCash) Then
		PettyCash = Catalogs.PettyCashes.CreateItem();
		PettyCash.Description = "Main petty cash";
		PettyCash.CurrencyByDefault = Structure.AccountingCurrency;
		PettyCash.GLAccount = ChartsOfAccounts.Managerial.PettyCash;
		PettyCash.Write();
	EndIf;
	
	// Fill in companies. // TODO Add another descriptions
	OurCompanyRef = Catalogs.Companies.MainCompany;
	OurCompany = OurCompanyRef.GetObject();
	FillPropertyValues(OurCompany, Structure.Company);
	
	OurCompany.PettyCashByDefault = PettyCash.Ref;
	OurCompany.BusinessCalendar   = SmallBusinessServer.GetCalendarByProductionCalendaRF();
	OurCompany.Write();
	
	// 11. Fill in prices kinds.
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
	// 5. Fill in contracts forms.
	FillContractsForms(Postfix);
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

Procedure FillContractsForms(Postfix)
	
	If ThisIsRu(Postfix) Then 
		FillContractsFormsRu();
	Else
		FillContractsFormsDefault();
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
Procedure FillContractsFormsDefault()
	
	LeaseAgreementTemplate 			= Catalogs.ContractForms.GetTemplate("LeaseAgreementTemplate");
	PurchaseAndSaleContractTemplate 	= Catalogs.ContractForms.GetTemplate("PurchaseAndSaleContractTemplate");
	ServicesContractTemplate 	= Catalogs.ContractForms.GetTemplate("ServicesContractTemplate");
	SupplyContractTemplate 		= Catalogs.ContractForms.GetTemplate("SupplyContractTemplate");
	
	Templates = New Array(4);
	Templates[0] = LeaseAgreementTemplate;
	Templates[1] = PurchaseAndSaleContractTemplate;
	Templates[2] = ServicesContractTemplate;
	Templates[3] = SupplyContractTemplate;
	
	LayoutNames = New Array(4);
	LayoutNames[0] = "LeaseAgreementTemplate";
	LayoutNames[1] = "PurchaseAndSaleContractTemplate";
	LayoutNames[2] = "ServicesContractTemplate";
	LayoutNames[3] = "SupplyContractTemplate";
	
	Forms = New Array(4);
	Forms[0] = Catalogs.ContractForms.LeaseAgreement.Ref.GetObject();
	Forms[1] = Catalogs.ContractForms.PurchaseAndSaleContract.Ref.GetObject();
	Forms[2] = Catalogs.ContractForms.ServicesContract.Ref.GetObject();
	Forms[3] = Catalogs.ContractForms.SupplyContract.Ref.GetObject();
	
	Iterator = 0;
	While Iterator < Templates.Count() Do 
		
		ContractTemplate = Catalogs.ContractForms.GetTemplate(LayoutNames[Iterator]);
		
		TextHTML = ContractTemplate.GetText();
		Attachments = New Structure;
		
		EditableParametersNumber = StrOccurrenceCount(TextHTML, "{FilledField");
		
		Forms[Iterator].EditableParameters.Clear();
		ParameterNumber = 1;
		While ParameterNumber <= EditableParametersNumber Do 
			NewRow = Forms[Iterator].EditableParameters.Add();
			NewRow.Presentation = "{FilledField" + ParameterNumber + "}";
			NewRow.ID = "parameter" + ParameterNumber;
			
			ParameterNumber = ParameterNumber + 1;
		EndDo;
		
		FormattedDocumentStructure = New Structure;
		FormattedDocumentStructure.Insert("HTMLText", TextHTML);
		FormattedDocumentStructure.Insert("Attachments", Attachments);
		
		Forms[Iterator].Form = New ValueStorage(FormattedDocumentStructure);
		Forms[Iterator].PredefinedFormTemplate = LayoutNames[Iterator];
		Forms[Iterator].EditableParametersNumber = EditableParametersNumber;
		Forms[Iterator].Write();
		
		Iterator = Iterator + 1;
		
	EndDo;
	
EndProcedure

// 6.
Procedure FillInformationAboutNewCompanyDefault(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull",       "LLC ""Our company""");
	StructureCompany.Insert("Prefix",                "OF-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice",     True);
	
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
Procedure FillClassifierOfWorkingTimeUsageRu()
	
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
Procedure FillContractsFormsRu()
	
	LeaseAgreementTemplate 			= Catalogs.ContractForms.GetTemplate("LeaseAgreementTemplate");
	PurchaseAndSaleContractTemplate 	= Catalogs.ContractForms.GetTemplate("PurchaseAndSaleContractTemplate");
	ServicesContractTemplate 	= Catalogs.ContractForms.GetTemplate("ServicesContractTemplate");
	SupplyContractTemplate 		= Catalogs.ContractForms.GetTemplate("SupplyContractTemplate");
	
	Templates = New Array(4);
	Templates[0] = LeaseAgreementTemplate;
	Templates[1] = PurchaseAndSaleContractTemplate;
	Templates[2] = ServicesContractTemplate;
	Templates[3] = SupplyContractTemplate;
	
	LayoutNames = New Array(4);
	LayoutNames[0] = "LeaseAgreementTemplate";
	LayoutNames[1] = "PurchaseAndSaleContractTemplate";
	LayoutNames[2] = "ServicesContractTemplate";
	LayoutNames[3] = "SupplyContractTemplate";
	
	Forms = New Array(4);
	Forms[0] = Catalogs.ContractForms.LeaseAgreement.Ref.GetObject();
	Forms[1] = Catalogs.ContractForms.PurchaseAndSaleContract.Ref.GetObject();
	Forms[2] = Catalogs.ContractForms.ServicesContract.Ref.GetObject();
	Forms[3] = Catalogs.ContractForms.SupplyContract.Ref.GetObject();
	
	Iterator = 0;
	While Iterator < Templates.Count() Do 
		
		ContractTemplate = Catalogs.ContractForms.GetTemplate(LayoutNames[Iterator]);
		
		TextHTML = ContractTemplate.GetText();
		Attachments = New Structure;
		
		EditableParametersNumber = StrOccurrenceCount(TextHTML, "{FilledField");
		
		Forms[Iterator].EditableParameters.Clear();
		ParameterNumber = 1;
		While ParameterNumber <= EditableParametersNumber Do 
			NewRow = Forms[Iterator].EditableParameters.Add();
			NewRow.Presentation = "{FilledField" + ParameterNumber + "}";
			NewRow.ID = "parameter" + ParameterNumber;
			
			ParameterNumber = ParameterNumber + 1;
		EndDo;
		
		FormattedDocumentStructure = New Structure;
		FormattedDocumentStructure.Insert("HTMLText", TextHTML);
		FormattedDocumentStructure.Insert("Attachments", Attachments);
		
		Forms[Iterator].Form = New ValueStorage(FormattedDocumentStructure);
		Forms[Iterator].PredefinedFormTemplate = LayoutNames[Iterator];
		Forms[Iterator].EditableParametersNumber = EditableParametersNumber;
		Forms[Iterator].Write();
		
		Iterator = Iterator + 1;
		
	EndDo;
	
EndProcedure

// 6.
Procedure FillInformationAboutNewCompanyRu(Structure)

	StructureCompany = New Structure;
	StructureCompany.Insert("DescriptionFull", "LLC ""Our company""");
	StructureCompany.Insert("Prefix", "OF-""");
	StructureCompany.Insert("LegalEntityIndividual", Enums.LegalEntityIndividual.LegalEntity);
	StructureCompany.Insert("IncludeVATInPrice", True);
	
	Structure.Insert("Company", StructureCompany);
	
EndProcedure

#EndRegion

#EndRegion

#Region DefinedCountry

Function ThisIsRu(Postfix)
	Return Postfix = Upper("Ru");
EndFunction 

Function ThisIsEn(Postfix)
	Return Postfix = Upper("Ru");
EndFunction 

Function ArrayOfPostfix()
	
	// TODO
	ArrayOfPostfix = New Array;
	ArrayOfPostfix.Add(Upper("En"));
	ArrayOfPostfix.Add(Upper("Ru"));
	ArrayOfPostfix.Add(Upper("Ro"));
	Return ArrayOfPostfix;
	
EndFunction

#EndRegion