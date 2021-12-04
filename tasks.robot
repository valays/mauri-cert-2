*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...
...               This robot created by Mauri Tikka / Väläys Oy 2021 for certification purposes.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Desktop
Library           RPA.Archive
Library           RPA.Robocorp.Vault

*** Variables ***
${ORDERING_URL}    https://robotsparebinindustries.com/
${ORDERFILE}      orders.csv
${RETRIES}        4 times

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    ${RETRIES}    4s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close All Browsers

*** Keywords ***
Open the robot order website
    Open Available Browser    ${ORDERING_URL}
    # No need for manual log switch, keywords do it automatically
    # ${level}    Set Log Level    NONE
    ${secret}    Get Secret    RobotSpareBin
    Input Text    username    ${secret}[username]
    Input Password    password    ${secret}[password]
    Submit Form
    # Set Log Level    ${level}
    Wait Until Page Contains Element    id:sales-form
    Click Link    Order your robot!

Get orders
    Download    ${ORDERING_URL}/${ORDERFILE}    overwrite=True
    ${orders}=    Read table from CSV    ${ORDERFILE}    header=True
    [Return]    ${orders}

Close the annoying modal
    # The sneaky bastards have the text altered by CSS,
    # so page code contains text which is not capitalized. Clever!
    Wait Until Page Contains    By using this order form
    Click Button    Yep

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    5    #id:id-body-${order}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains    Receipt

Store the receipt as a PDF file
    [Arguments]    ${ordernumber}
    ${pdf}    Set Variable    ${OUTPUT_DIR}${/}receipt-${ordernumber}.pdf
    ${html}    Get Element Attribute    receipt    innerHTML
    Html To Pdf    ${html}    ${pdf}
    [Return]    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${ordernumber}
    ${image}    Set Variable    ${OUTPUT_DIR}${/}robot-image-${ordernumber}.png
    Screenshot    robot-preview-image    ${image}
    [Return]    ${image}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${image}    ${pdf}
    @{images}    Create List    ${image}
    Add Files To Pdf    ${images}    ${pdf}    append=True

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}orders.zip    include=receipt-*.pdf
