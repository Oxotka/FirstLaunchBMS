
Function PredifenedDateAtServer(Postfix) Export
	
	Structure = New Structure("Currency, Company, NameOfCompany");
	
	Postfix = Upper(Postfix);
	If ArrayOfPostfix().Find(Postfix) = Undefined Then
		// Use default fill first data
		Structure.NameOfCompany = "Our company";
		Return Structure;
	Else
		PredifenedDateAtServerForCountry(Postfix);
		Structure.NameOfCompany = "Наша компания";
		Return Structure;
	EndIf;
	
EndFunction

&AtServer
Procedure PredifenedDateAtServerForCountry(Postfix)
	
	// 1. Fill tax types
	FillTaxTypesFirstLaunch(Postfix);
	
	
EndProcedure


Procedure FillTaxTypesFirstLaunch(Postfix)
	
	If Postfix = "EN" Then 
		FillTaxTypesFirstLaunchEn();
	ElsIf Postfix = "RU" Then
		FillTaxTypesFirstLaunchRu();
	EndIf
	

EndProcedure // FillTaxTypesFirstLaunch()

#Region En

// 1.
Procedure FillTaxTypesFirstLaunchEn()
	
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

#EndRegion

#Region Ru

// 1.
Procedure FillTaxTypesFirstLaunchRu()
	
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


#EndRegion

Function ArrayOfPostfix()

	ArrayOfPostfix = New Array;
	ArrayOfPostfix.Add(Upper("En"));
	ArrayOfPostfix.Add(Upper("Ru"));
	ArrayOfPostfix.Add(Upper("Ro"));
	Return ArrayOfPostfix;

EndFunction