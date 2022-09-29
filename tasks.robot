*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Variables           variables/variables.py
Library             RPA.HTTP
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs


*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${CURDIR}${/}temp


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${url}=    Get CSV URL from user input
    ${orders}=    Get orders    ${url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Task Teardown Actions


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    ${MODAL_BUTTON}

Get CSV URL from user input
    Add heading    CSV file URL
    Add text input    url
    ...    label=CSV file URL
    ...    placeholder=Enter download URL for CSV file
    ${csv_url}=    Run dialog
    RETURN    ${csv_url.url}

Get orders
    [Arguments]    ${csv_url}
    Log To Console    ${csv_url}
    IF    "${csv_url}" == ""
        ${csv_url}=    Set Variable    https://robotsparebinindustries.com/orders.csv
    END
    Download    ${csv_url}
    ${table}=    Read table from CSV    orders.csv    delimiters=,
    RETURN    ${table}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order
    ${error_visible}=    Is Element Visible    css:div.alert-danger
    WHILE    ${error_visible}
        Click Button    Order
        ${error_visible}=    Is Element Visible    css:div.alert-danger
    END

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${pdf_name}=    Set Variable    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt-${order_number}.pdf
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_name}
    RETURN    ${pdf_name}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot_name}=    Set Variable    ${OUTPUT_DIR}${/}robot-image-${order_number}.png
    Screenshot    css:div#robot-preview-image    ${screenshot_name}
    RETURN    ${screenshot_name}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${file}=    Create List    ${screenshot}
    Add Files To Pdf    ${file}    ${pdf}    append=${True}

Go to order another robot
    Click Button    Order another robot

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Task Teardown Actions
    Cleanup temporary PDF directory
    Close All Browsers

Cleanup temporary PDF directory
    TRY
        Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True
    EXCEPT    FileNotFoundError*
        Log    PDF temp directory not found
    END
