//
//  PaymentSheetFormFactoryTest.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeUICore

class MockElement: Element {
    var paramsUpdater: (IntentConfirmParams) -> IntentConfirmParams?
    
    init(paramsUpdater: @escaping (IntentConfirmParams) -> IntentConfirmParams?) {
        self.paramsUpdater = paramsUpdater
    }
    
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return paramsUpdater(params)
    }
    
    weak var delegate: ElementDelegate?
    lazy var view: UIView = { UIView() }()
}

class PaymentSheetFormFactoryTest: XCTestCase {
    func testUpdatesParams() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Name"
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .SEPADebit
        )
        let name = factory.makeFullName()
        let email = factory.makeEmail()
        let checkbox = factory.makeSaveCheckbox { _ in }
        
        let form = FormElement(elements: [name, email, checkbox])
        let params = form.updateParams(params: IntentConfirmParams(type: .SEPADebit))

        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.name, "Name")
        XCTAssertEqual(params?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
    }

    func testSpecFromJSONProvider() {
        let e = expectation(description: "Loads form specs file")
        let provider = FormSpecProvider()
        provider.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .EPS
        )

        guard let spec = factory.specFromJSONProvider(provider: provider) else {
            XCTFail("Unable to load EPS Spec")
            return
        }

        XCTAssertEqual(spec.fields.count, 2)
        XCTAssertEqual(spec.fields.first, .name(.init(apiPath: ["v1": "billing_details[name]"])))
    }

    func testNameOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let name = factory.makeFullName(apiPath: "custom_location[name]")
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = name.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"] as! String, "someName")
    }

    func testNameValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let name = factory.makeFullName()
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = name.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"])
    }

    func testNameValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let nameSpec = FormSpec.BaseFieldSpec(apiPath: ["v1": "custom_location[name]"])
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.name(nameSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.name)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"] as! String, "someName")
    }

    func testNameValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "someName"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let nameSpec = FormSpec.BaseFieldSpec(apiPath: nil)
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.name(nameSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[name]"])
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.name, "someName")
    }

    func testEmailOverrideApiPathBySpec() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let email = factory.makeEmail(apiPath: "custom_location[email]")
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"] as! String, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
    }

    func testEmailValueWrittenToDefaultLocation() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let email = factory.makeEmail()
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = email.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"])
    }

    func testEmailValueWrittenToLocationDefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )
        let emailSpec = FormSpec.BaseFieldSpec(apiPath: ["v1": "custom_location[email]"])
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.email(emailSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.email)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"] as! String, "email@stripe.com")
    }

    func testEmailValueWrittenToLocationUndefinedAPIPath() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = "email@stripe.com"
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .unknown
        )

        let emailSpec = FormSpec.BaseFieldSpec(apiPath: nil)
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.email(emailSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.email, "email@stripe.com")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[email]"])
    }
    
    func testMakeFormElement_dropdown() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .SEPADebit
        )
        let selectorSpec = FormSpec.SelectorSpec(label: .eps_bank,
                                                 items: [.init(displayText: "d1", apiValue: "123"),
                                                         .init(displayText: "d2", apiValue: "456")],
                                                 apiPath: ["v1": "custom_location[selector]"])
        let spec = FormSpec(type: "mock_pm", async: false, fields: [.selector(selectorSpec)])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_location[selector]"] as! String, "123")
    }

    func testMakeFormElement_KlarnaCountry_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .klarna
        )
        let spec = FormSpec(type: "mock_klarna",
                            async: false,
                            fields: [.klarna_country(.init(apiPath: nil))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "US")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["billing_details[address][country]"])
    }

    func testMakeFormElement_KlarnaCountry_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .klarna
        )
        let spec = FormSpec(type: "mock_klarna",
                            async: false,
                            fields: [.klarna_country(.init(apiPath:["v1":"billing_details[address][country]"]))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.billingDetails?.address?.country)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["billing_details[address][country]"] as! String, "US")
    }

    func testMakeFormElement_BSBNumber() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let bsb = factory.makeBSB(apiPath: nil)
        bsb.element.setText("000-000")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = bsb.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"])
    }

    func testMakeFormElement_BSBNumber_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let bsb = factory.makeBSB(apiPath: "custom_path[bsb_number]")
        bsb.element.setText("000-000")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = bsb.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_path[bsb_number]"] as! String, "000000")
    }

    func testMakeFormElement_BSBNumber_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let spec = FormSpec(type: "mock_aubecs",
                            async: false,
                            fields: [.au_becs_bsb_number(.init(apiPath: nil))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000-000")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber, "000000")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"])
    }

    func testMakeFormElement_BSBNumber_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let spec = FormSpec(type: "mock_aubecs",
                            async: false,
                            fields: [.au_becs_bsb_number(.init(apiPath: ["v1":"au_becs_debit[bsb_number]"]))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000-000")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.bsbNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[bsb_number]"] as! String, "000000")
    }

    func testMakeFormElement_AUBECSAccountNumber_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let spec = FormSpec(type: "mock_aubecs",
                            async: false,
                            fields: [.au_becs_account_number(.init(apiPath: nil))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000123456")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber, "000123456")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[account_number]"])
    }

    func testMakeFormElement_AUBECSAccountNumber_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let spec = FormSpec(type: "mock_aubecs",
                            async: false,
                            fields: [.au_becs_account_number(.init(apiPath: ["v1":"au_becs_debit[account_number]"]))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("000123456")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[account_number]"] as! String, "000123456")
    }

    func testMakeFormElement_AUBECSAccountNumber() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let accountNum = factory.makeAUBECSAccountNumber(apiPath: nil)
        accountNum.element.setText("000123456")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber, "000123456")
        XCTAssertNil(updatedParams?.paymentMethodParams.additionalAPIParameters["au_becs_debit[account_number]"])
    }

    func testMakeFormElement_AUBECSAccountNumber_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit
        )
        let accountNum = factory.makeAUBECSAccountNumber(apiPath: "custom_path[account_number]")
        accountNum.element.setText("000123456")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.auBECSDebit?.accountNumber)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["custom_path[account_number]"] as! String, "000123456")
    }

    func testMakeFormElement_SofortBillingAddress_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .sofort
        )
        let spec = FormSpec(type: "mock_sofort",
                            async: false,
                            fields: [.sofort_billing_address(.init(apiPath: nil, validCountryCodes: ["AT", "BE"]))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.sofort?.country, "AT")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
    }

    func testMakeFormElement_SofortBillingAddress_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .sofort
        )
        let spec = FormSpec(type: "mock_sofort",
                            async: false,
                            fields: [.sofort_billing_address(.init(apiPath: ["v1":"sofort[country]"], validCountryCodes: ["AT", "BE"]))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)

        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sofort?.country)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sofort[country]"] as! String, "AT")
    }

    func testMakeFormElement_SofortBillingAddress() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .sofort
        )
        let accountNum = factory.makeSofortBillingAddress(countryCodes: ["AT", "BE"], apiPath: nil)

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.sofort?.country, "AT")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
    }

    func testMakeFormElement_SofortBillingAddress_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .sofort
        )
        let accountNum = factory.makeSofortBillingAddress(countryCodes: ["AT", "BE"], apiPath: "sofort[country]")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sofort?.country)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sofort[country]"] as! String, "AT")
    }

    func testMakeFormElement_Iban_UndefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .SEPADebit
        )
        let spec = FormSpec(type: "mock_sepa_debit",
                            async: false,
                            fields: [.iban(.init(apiPath: nil))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("GB33BUKB20201555555555")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.sepaDebit?.iban, "GB33BUKB20201555555555")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
    }

    func testMakeFormElement_Iban_DefinedAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .SEPADebit
        )
        let spec = FormSpec(type: "mock_sepa_debit",
                            async: false,
                            fields: [.iban(.init(apiPath: ["v1": "sepa_debit[iban]"]))])
        let formElement = factory.makeFormElementFromSpec(spec: spec)
        let params = IntentConfirmParams(type: .unknown)
        guard let wrappedElement = firstWrappedTextFieldElement(formElement: formElement) else {
            XCTFail("Unable to get firstElement")
            return
        }

        wrappedElement.element.setText("GB33BUKB20201555555555")
        let updatedParams = formElement.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sepaDebit?.iban)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sepa_debit[iban]"] as! String, "GB33BUKB20201555555555")
    }

    func testMakeFormElement_Iban() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .SEPADebit
        )
        let iban = factory.makeIban(apiPath: nil)
        iban.element.setText("GB33BUKB20201555555555")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = iban.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.sepaDebit?.iban, "GB33BUKB20201555555555")
        XCTAssert(updatedParams?.paymentMethodParams.additionalAPIParameters.isEmpty ?? false)
    }

    func testMakeFormElement_Iban_withAPIPath() {
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .SEPADebit
        )
        let iban = factory.makeIban(apiPath: "sepa_debit[iban]")
        iban.element.setText("GB33BUKB20201555555555")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = iban.updateParams(params: params)

        XCTAssertNil(updatedParams?.paymentMethodParams.sepaDebit?.iban)
        XCTAssertEqual(updatedParams?.paymentMethodParams.additionalAPIParameters["sepa_debit[iban]"] as! String, "GB33BUKB20201555555555")
    }

    func testMakeFormElement_BillingAddress() {
        let addressSpecProvider = AddressSpecProvider()
        addressSpecProvider.addressSpecs = ["US": AddressSpec(format: "%N%n%O%n%A%n%C, %S %Z",
                                                              require: "ACSZ",
                                                              cityNameType: nil,
                                                              stateNameType: .state,
                                                              zip: "\\d{5}",
                                                              zipNameType: .zip)]
        let configuration = PaymentSheet.Configuration()
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            configuration: configuration,
            paymentMethod: .AUBECSDebit,
            addressSpecProvider: addressSpecProvider
        )
        let accountNum = factory.makeBillingAddressSection()
        accountNum.element.line1?.setText("123 main")
        accountNum.element.line2?.setText("#501")
        accountNum.element.city?.setText("AnywhereTown")
        accountNum.element.state?.setText("California")
        accountNum.element.postalCode?.setText("55555")

        let params = IntentConfirmParams(type: .unknown)
        let updatedParams = accountNum.updateParams(params: params)

        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.line1, "123 main")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.line2, "#501")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.country, "US")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.city, "AnywhereTown")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.state, "California")
        XCTAssertEqual(updatedParams?.paymentMethodParams.billingDetails?.address?.postalCode, "55555")
    }

    func testNonCardsDontHaveCheckbox() {
        let configuration = PaymentSheet.Configuration()
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent())
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin),
        ]
        let loadFormSpecs = expectation(description: "Load form specs")
        FormSpecProvider.shared.load { _ in
            loadFormSpecs.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        for type in PaymentSheet.supportedPaymentMethods.filter({ $0 != .card && $0 != .USBankAccount }) {
            let factory = PaymentSheetFormFactory(
                intent: intent,
                configuration: configuration,
                paymentMethod: type,
                addressSpecProvider: specProvider
            )
            
            guard let form = factory.make() as? FormElement else {
                XCTFail()
                return
            }
            XCTAssertFalse(form.getAllSubElements().contains {
                $0 is PaymentMethodElementWrapper<CheckboxElement> || $0 is CheckboxElement
            })
        }
    }
    
    func testShowsCardCheckbox() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: configuration,
            paymentMethod: .card
        )
        XCTAssertEqual(factory.saveMode, .userSelectable)
    }

    func testEPSDoesntHideCardCheckbox() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card, .EPS])
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: configuration,
            paymentMethod: .card
        )
        XCTAssertEqual(factory.saveMode, .userSelectable)
    }

    func testBillingAddressSection() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco", country: "US", line1: "510 Townsend St.", line2: "Line 2", postalCode: "94102", state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "sec")
        configuration.defaultBillingDetails.address = defaultAddress
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [.card])
        // An address section with defaults...
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        let factory = PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: configuration,
            paymentMethod: .card,
            addressSpecProvider: specProvider
        )
        let addressSection = factory.makeBillingAddressSection()

        // ...should update params
        let intentConfirmParams = addressSection.updateParams(params: IntentConfirmParams(type: .card))
        guard let billingDetails = intentConfirmParams?.paymentMethodParams.billingDetails?.address else {
            XCTFail()
            return
        }

        XCTAssertEqual(billingDetails.line1, defaultAddress.line1)
        XCTAssertEqual(billingDetails.line2, defaultAddress.line2)
        XCTAssertEqual(billingDetails.city, defaultAddress.city)
        XCTAssertEqual(billingDetails.postalCode, defaultAddress.postalCode)
        XCTAssertEqual(billingDetails.state, defaultAddress.state)
        XCTAssertEqual(billingDetails.country, defaultAddress.country)
    }

    private func firstWrappedTextFieldElement(formElement: FormElement) -> PaymentMethodElementWrapper<TextFieldElement>? {
        guard let sectionElement = formElement.elements.first as? SectionElement,
              let wrappedElement = sectionElement.elements.first as? PaymentMethodElementWrapper<TextFieldElement> else {
                  return nil
              }
        return wrappedElement
    }
}
