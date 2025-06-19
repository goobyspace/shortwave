local _, core = ...
core.Popup = {}
local Popup = core.Popup

local function createPopupFrame()
    do
        Popup.frame = CreateFrame("Frame", "ShortWavePopupFrame", UIParent, "DefaultPanelTemplate")
        Popup.frame:SetSize(250, 110)
        Popup.frame:SetFrameStrata("TOOLTIP")
        Popup.frame:SetPoint("CENTER", core.PlayerWindow.window, "CENTER")
        Popup.frame:SetMouseMotionEnabled(true)
        Popup.frame:SetPropagateMouseMotion(false)
        Popup.frame:SetMouseClickEnabled(true)
        Popup.frame:SetPropagateMouseClicks(false)

        Popup.frame.closeButton = CreateFrame("Button", nil,
            Popup.frame, "UIPanelCloseButton")
        Popup.frame.closeButton:SetPoint("TOPRIGHT", Popup.frame, "TOPRIGHT", -1, -2)
        Popup.frame.closeButton:SetSize(20, 20)
        Popup.frame.closeButton:SetScript("OnClick", function()
            Popup.frame:Hide()
        end)

        Popup.frame.title = Popup.frame.TitleContainer:CreateFontString("TITLETEXT");
        Popup.frame.title:SetFontObject("GameFontNormal")
        Popup.frame.title:SetPoint("CENTER")
        Popup.frame.title:SetText("Popup")
        Popup.frame.title:SetWidth(200)
        Popup.frame.title:SetHeight(10)

        Popup.frame.texture = Popup.frame:CreateTexture("TopBarTexture", "BACKGROUND")
        Popup.frame.texture:SetPoint("TOPLEFT", Popup.frame, "TOPLEFT", 8, 0)
        Popup.frame.texture:SetPoint("BOTTOMRIGHT", Popup.frame, "BOTTOMRIGHT", -3, 2)
        Popup.frame.texture:SetTexture("Interface/FrameGeneral/UI-Background-Rock")
        Popup.frame.texture:SetHorizTile(true)
        Popup.frame.texture:SetVertTile(true)
        Popup.frame:Hide()
    end

    do
        Popup.frame.confirmationWindow = CreateFrame("Frame", "ShortWaveConfirmationWindow", Popup.frame)
        Popup.frame.confirmationWindow:SetSize(240, 84)
        Popup.frame.confirmationWindow:SetPoint("TOP", Popup.frame, "TOP", 4, -24)

        Popup.frame.confirmationWindow.text = Popup.frame.confirmationWindow:CreateFontString("ConfirmationText")
        Popup.frame.confirmationWindow.text:SetFontObject("GameFontNormal")
        Popup.frame.confirmationWindow.text:SetPoint("TOP", Popup.frame.confirmationWindow, "TOP", 0, -4)
        Popup.frame.confirmationWindow.text:SetText("Are you sure?")
        Popup.frame.confirmationWindow.text:SetJustifyH("CENTER")
        Popup.frame.confirmationWindow.text:SetJustifyV("MIDDLE")
        Popup.frame.confirmationWindow.text:SetWidth(220)
        Popup.frame.confirmationWindow.text:SetHeight(50)

        Popup.frame.confirmationWindow.confirmButton = CreateFrame("Button", "ConfirmationButton",
            Popup.frame.confirmationWindow, "UIPanelButtonTemplate")
        Popup.frame.confirmationWindow.confirmButton:SetSize(66, 22)
        Popup.frame.confirmationWindow.confirmButton:SetPoint("BOTTOM", Popup.frame.confirmationWindow, "BOTTOM", -40,
            4)
        Popup.frame.confirmationWindow.confirmButton:SetText("Confirm")
        Popup.frame.confirmationWindow.confirmButton:SetScript("OnClick", function()
            Popup.frame:Hide()
            if Popup.callback then
                Popup.callback()
            end
        end)

        Popup.frame.confirmationWindow.cancelButton = CreateFrame("Button", "CancelButton",
            Popup.frame.confirmationWindow, "UIPanelButtonTemplate")
        Popup.frame.confirmationWindow.cancelButton:SetSize(66, 22)
        Popup.frame.confirmationWindow.cancelButton:SetPoint("BOTTOM", Popup.frame.confirmationWindow, "BOTTOM",
            40, 4)
        Popup.frame.confirmationWindow.cancelButton:SetText("Cancel")
        Popup.frame.confirmationWindow.cancelButton:SetScript("OnClick", function()
            Popup.frame:Hide()
        end)

        Popup.frame.confirmationWindow:Hide()
    end

    do
        Popup.frame.editWindow = CreateFrame("Frame", "ShortWaveEditWindow", Popup.frame)
        Popup.frame.editWindow:SetSize(240, 84)
        Popup.frame.editWindow:SetPoint("TOP", Popup.frame, "TOP", 4, -24)

        Popup.frame.editWindow.text = Popup.frame.editWindow:CreateFontString("ConfirmationText")
        Popup.frame.editWindow.text:SetFontObject("GameFontNormal")
        Popup.frame.editWindow.text:SetPoint("TOP", Popup.frame.editWindow, "TOP", 0, -2)
        Popup.frame.editWindow.text:SetText("Are you sure?")
        Popup.frame.editWindow.text:SetJustifyH("CENTER")
        Popup.frame.editWindow.text:SetJustifyV("MIDDLE")
        Popup.frame.editWindow.text:SetWidth(220)
        Popup.frame.editWindow.text:SetHeight(28)


        Popup.frame.editWindow.input = CreateFrame("EditBox", "EditInput", Popup.frame.editWindow, "InputBoxTemplate")
        Popup.frame.editWindow.input:SetSize(220, 20)
        Popup.frame.editWindow.input:SetPoint("CENTER", Popup.frame.editWindow, "CENTER", 0, 0)
        Popup.frame.editWindow.input:SetMaxLetters(28);
        Popup.frame.editWindow.input:SetText("Enter playlist name");

        local function validateInput()
            local inputText = Popup.frame.editWindow.input:GetText()
            if Popup.validation and type(Popup.validation) == "function" then
                local errorMessage = Popup.validation(inputText)
                if errorMessage then
                    Popup.frame.editWindow.text:SetText(errorMessage or "Invalid input")
                else
                    Popup.callback(inputText)
                    Popup.frame:Hide()
                end
            end
        end

        Popup.frame.editWindow.input:SetScript("OnEnterPressed", function()
            validateInput()
        end)

        Popup.frame.editWindow.confirmButton = CreateFrame("Button", "ConfirmationButton",
            Popup.frame.editWindow, "UIPanelButtonTemplate")
        Popup.frame.editWindow.confirmButton:SetSize(66, 22)
        Popup.frame.editWindow.confirmButton:SetPoint("BOTTOM", Popup.frame.editWindow, "BOTTOM", -40,
            4)
        Popup.frame.editWindow.confirmButton:SetText("Confirm")
        Popup.frame.editWindow.confirmButton:SetScript("OnClick", function()
            validateInput()
        end)

        Popup.frame.editWindow.cancelButton = CreateFrame("Button", "CancelButton",
            Popup.frame.editWindow, "UIPanelButtonTemplate")
        Popup.frame.editWindow.cancelButton:SetSize(66, 22)
        Popup.frame.editWindow.cancelButton:SetPoint("BOTTOM", Popup.frame.editWindow, "BOTTOM",
            40, 4)
        Popup.frame.editWindow.cancelButton:SetText("Cancel")
        Popup.frame.editWindow.cancelButton:SetScript("OnClick", function()
            Popup.frame:Hide()
        end)

        Popup.frame.editWindow:Hide()
    end
end

function Popup:Confirmation(message, title, callback)
    if not Popup.frame then
        createPopupFrame()
    end
    Popup.frame.title:SetText(title or "Popup")
    Popup.frame.confirmationWindow.text:SetText(message or "Are you sure?")
    Popup.callback = callback
    Popup.frame.confirmationWindow:Show()
    Popup.frame.editWindow:Hide()
    Popup.frame:Show()
end

function Popup:Edit(message, title, startingValue, callback, validation)
    if not Popup.frame then
        createPopupFrame()
    end
    Popup.frame.title:SetText(title or "Popup")
    Popup.frame.editWindow.text:SetText(message or "Edit:")
    Popup.frame.editWindow.input:SetText(startingValue or "")
    Popup.callback = callback
    Popup.validation = validation
    Popup.frame.confirmationWindow:Hide()
    Popup.frame.editWindow:Show()
    Popup.frame:Show()
end
