*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
...             https://robocorp.com/docs/courses/build-a-robot
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Variables ***
${save_path} =    ${CURDIR}${/}output${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csv_site_url}=    Get site url from vault
    ${csvFile}=    Get data from user
    # site url: https://robotsparebinindustries.com/
    # csv file: orders.csv
    Download    ${csv_site_url}${csvFile}  overwrite=True
    ${orders}=  Read table from CSV    orders.csv  header=True
    Open the robot order website
    FOR    ${row}  IN  @{orders}
        Fill the form    ${row}
        Click Button    id: preview
        Wait Until Keyword Succeeds    10x    4s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Log    Done.

*** Keywords ***
Open the robot order website
    Open Available Browser	https://robotsparebinindustries.com/#/robot-order
    Click Button	class: btn-dark

Fill the form
    [Arguments]  ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text     css:input[type="number"]     ${row}[Legs]
    Input Text    css:input[name="address"]     ${row}[Address]
    
Submit the order
    Click Button    id:order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${save_path}receipt_${order_number}.pdf
    [Return]    ${save_path}receipt_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot     id:robot-preview    ${save_path}robot_${order_number}.png
    [Return]       ${save_path}robot_${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log    ${pdf}
    #Open Pdf       ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}    append=True
    #Close Pdf      ${pdf}

Go to order another robot
    Click Button    order-another
    Wait Until Element Is Visible    class: btn-dark
    Click Button	class: btn-dark

Create a ZIP file of the receipts
    Archive Folder With Zip    folder=${save_path}    archive_name=orders_receipts.zip  include=*.pdf

Get data from user
    Add text input    csvFile    label=Please type your CSV file name
    ${response}=    Run dialog    title=type: orders.csv
    [Return]    ${response.csvFile}

Get site url from vault
    ${vault_data}=   Get Secret    vault_level2  
    [Return]    ${vault_data}[csv_site_url]
