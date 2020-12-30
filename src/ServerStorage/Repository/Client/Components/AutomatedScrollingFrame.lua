local function AutomatedScrollingFrame(ScrollingFrame: ScrollingFrame, UIGridStyleLayout: UIGridStyleLayout?)
	UIGridStyleLayout = UIGridStyleLayout or ScrollingFrame:FindFirstChildWhichIsA("UIGridStyleLayout")
	local function UpdateFrame()
		local AbsoluteContentSize = UIGridStyleLayout.AbsoluteContentSize
		ScrollingFrame.CanvasSize = UDim2.fromOffset(AbsoluteContentSize.X, AbsoluteContentSize.Y)
	end

	UpdateFrame()
	return UIGridStyleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateFrame)
end

return AutomatedScrollingFrame