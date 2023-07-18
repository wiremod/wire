------------------------------------------------------------------------------------------------
--	Purpose: contains functionality for wrapping text to a specific width and expanding spaces
--	so the text is aligned on both sides
------------------------------------------------------------------------------------------------



local TextWrapIndex = {};
TextWrapIndex.__index = TextWrapIndex;

-- name of the font to use - this should be the last thing you set
AccessorFunc( TextWrapIndex, "m_FontName", "Font" );
-- the contents of this object
AccessorFunc( TextWrapIndex, "m_Text", "Text" );
-- width and height of the box
AccessorFunc( TextWrapIndex, "w", "Wide" );
AccessorFunc( TextWrapIndex, "h", "Tall" );
-- should text be cut off if it exceeds the height?
AccessorFunc( TextWrapIndex, "m_LimitHeight", "LimitHeight" );
-- the width of the tab character
AccessorFunc( TextWrapIndex, "m_TabWidth", "TabWidth" );
-- spacing between lines
AccessorFunc( TextWrapIndex, "m_Spacing", "Spacing" );
-- position of the object
AccessorFunc( TextWrapIndex, "x", "OffsetX" );
AccessorFunc( TextWrapIndex, "y", "OffsetY" );
-- string to be appended when text is cut off -
-- either if the word is too long or the height is exceeded
-- this length of this text is not taken into account, so it should be something short
AccessorFunc( TextWrapIndex, "m_Cutoff", "CutoffText" );
AccessorFunc( TextWrapIndex, "m_HCutoff", "HeightCutoffText" );
-- should spaces be expanded to justify the text on both sides?
AccessorFunc( TextWrapIndex, "m_Justify", "Justify" );
-- should the last line in a paragraph also be justified?
AccessorFunc( TextWrapIndex, "m_JustifyLast", "JustifyLast" );

------------------------------------------------------------------------------------------------
--	Purpose: creates a new instance of TextWrap
------------------------------------------------------------------------------------------------
--function TextWrap( fontName )
function EGP:TextLayouter( fontName )

	local self = setmetatable( {}, TextWrapIndex );

	-- defaults
	self:SetText( "" );
	self:SetWide( 0 );
	self:SetTall( 0 );
	self:SetLimitHeight( false );
	self:SetTabWidth( 5 );
	self:SetSpacing( 0 );
	self:SetPos( 0, 0 );
	self:SetCutoffText( '-' );
	self:SetHeightCutoffText( ".." );
	self:SetJustify( true );
	self:SetJustifyLast( false );
	--self:SetWrap( true );
	self:SetFont( fontName or "default" );

	return self;

end

------------------------------------------------------------------------------------------------
--	Purpose: sets the font and caches some size values
------------------------------------------------------------------------------------------------
function TextWrapIndex:SetFont( fontName )

	self.m_FontName = fontName;

	surface.SetFont( fontName );

	-- cache these
	self.SpaceW, self.SpaceH		= surface.GetTextSize( ' ' );
	self.CharW, self.CharH		= surface.GetTextSize( 'W' );
	self.CutoffW, self.CutoffH	= surface.GetTextSize( self:GetCutoffText() );

end

------------------------------------------------------------------------------------------------
--	Purpose: gets the position
------------------------------------------------------------------------------------------------
function TextWrapIndex:GetPos()

	return self:GetOffsetX(), self:GetOffsetY();

end

------------------------------------------------------------------------------------------------
--	Purpose: sets the position
------------------------------------------------------------------------------------------------
function TextWrapIndex:SetPos( x, y )

	self:SetOffsetX( x );
	self:SetOffsetY( y );

end

------------------------------------------------------------------------------------------------
--	Purpose: gets the size
------------------------------------------------------------------------------------------------
function TextWrapIndex:GetSize()

	return self:GetWide(), self:GetTall();

end

------------------------------------------------------------------------------------------------
--	Purpose: sets the size
------------------------------------------------------------------------------------------------
function TextWrapIndex:SetSize( width, height )

	self:SetWide( width );
	self:SetTall( height );

end

------------------------------------------------------------------------------------------------
--	Purpose: gets the minimum width, clamp your stuff to this
------------------------------------------------------------------------------------------------
function TextWrapIndex:GetOptimalWidth()

	return self.CharW + self.SpaceW;

end

------------------------------------------------------------------------------------------------
--	Purpose: draws the wrapped text
------------------------------------------------------------------------------------------------
function TextWrapIndex:Draw()

	if( not self.TextData ) then

		self:Reset();

	end

	surface.SetFont( self:GetFont() );

	for i, textData in ipairs( self.TextData ) do

		-- no need to recompute every time we just want to move it
		surface.SetTextPos( self.x + textData[1], self.y + textData[2] );
		surface.DrawText( textData[3] );

	end

end

------------------------------------------------------------------------------------------------
--	Purpose: recomputes text alignment and return the net height of the text
------------------------------------------------------------------------------------------------
function TextWrapIndex:Reset()

	-- SplitWord will trigger an infinite loop if the width of the box is less than the
	-- max character width
	self:SetWide( math.max( self:GetOptimalWidth(), self:GetWide() ) );

	self.TextData = {}; -- { x, y, word }

	surface.SetFont( self:GetFont() );

	local y = 0;
	local numWords = 0;

	for paragraph in self:GetText():gmatch( "[^\n]+" ) do

		y, numWords = self:ComputeParagraph( paragraph, y, numWords );

	end

	if( numWords == 0 ) then return 0; end

	return y + self:GetSpacing() + self.CharH;

end

------------------------------------------------------------------------------------------------
--	Purpose: justifies words from startI to endI so they fit the width
------------------------------------------------------------------------------------------------
function TextWrapIndex:JustifyLine( width, startI, endI )

	if( not self:GetJustify() ) then return; end

	-- TODO: figure out why this needs to be here
	if( not self.TextData[ startI ] or not self.TextData[ endI ] ) then return; end

	-- calculate the new width of the space character
	local x = self.TextData[ startI ][1];
	local spaceW = math.max( self.SpaceW, ( self:GetWide() - width - x ) / ( endI - startI ) );

	for i = startI, endI do

		self.TextData[i][1] = x;

		x = x + surface.GetTextSize( self.TextData[i][3] ) + spaceW;

	end

end

------------------------------------------------------------------------------------------------
--	Purpose: splits long words and appends the cutoff text when needed
------------------------------------------------------------------------------------------------
function TextWrapIndex:SplitWord( word, width, x, y, lineWidth, lastI, numWords )

	-- no need to split, return what we got
	if( width <= self:GetWide() ) then

		return false, x, y, lineWidth, lastI, numWords;

	end

	local nextX = ( x == 0 and 0 or ( x + self.SpaceW ) ) + width;

	-- split up the word until it can fit
	while( nextX > self:GetWide() ) do

		-- calculate roughly where we want to cut
		local cutoffPos = math.floor( ( width - nextX + self:GetWide() ) / width * #word );

		-- only add it if there's something to cut off, else just move it down
		if( cutoffPos > 0 ) then

			-- split and append the cutoff text
			local part1 = word:sub( 1, cutoffPos )..self:GetCutoffText();
			-- start again with this word
			word = word:sub( cutoffPos + 1 );

			table.insert( self.TextData, { x, y, part1 } );

			--self:JustifyLine( lineWidth, lastI, numWords );

			numWords = numWords + 1;
			lastI = numWords;
			width = surface.GetTextSize( word );

		-- else

			-- self:JustifyLine( lineWidth, lastI, numWords );

		end

		x = 0;
		y = y + self.CharH + self:GetSpacing();
		nextX = width + self.SpaceW;

	end

	-- insert the remaining part
	table.insert( self.TextData, { x, y, word } );

	-- return the modified values
	-- this makes me hate Lua for not having some sort of pointer or reference features
	return true, x + width + self.SpaceW, y, nextX + self.SpaceW, lastI + 1, numWords + 1;

end

------------------------------------------------------------------------------------------------
--	Purpose: extracts words from this paragraph and splits long words properly
------------------------------------------------------------------------------------------------
function TextWrapIndex:ComputeParagraph( line, y, numWords )

	local x = 0;
	local lastI = numWords + 1;
	local lineWidth = 0;
	local splitWord = false;
	local onlyLine = true;

	for word in line:gmatch( "[^ ]+" ) do

		local width = surface.GetTextSize( word );

		-- split up words that won't fit even on the next line
		splitWord, x, y, lineWidth, lastI, numWords = self:SplitWord(
			word,
			width,
			x, y,
			lineWidth,
			lastI,
			numWords
		);



		-- the SplitWord method handles this stuff on its own
		if( not splitWord ) then

			-- this word exceeds the width, move it down
			if( ( x + self.SpaceW + width ) >= self:GetWide() ) then

				if (y + self.CharH > self:GetTall()) then
					self.TextData[#self.TextData][3] = string.Left( self.TextData[#self.TextData][3], -3 ) .. self:GetHeightCutoffText()
					break
				end

				-- justify the last line
				self:JustifyLine( lineWidth, lastI, numWords );

				x = 0;
				y = y + self.CharH + self:GetSpacing();
				lastI = numWords + 1;
				lineWidth = 0;
				onlyLine = false;

			end



			table.insert( self.TextData, { x, y, word } );

			x = x + self.SpaceW + width;
			lineWidth = lineWidth + width;
			numWords = numWords + 1;
			splitWord = false;

		else

			onlyLine = false;

		end

	end

	-- don't justify the last line if it's not the only one
	if( onlyLine ) then

		self:JustifyLine( lineWidth, lastI, numWords );

	end

	-- TODO: this sometimes adds an empty line, figure out why
	return y + self.CharH + self:GetSpacing(), numWords;

end
