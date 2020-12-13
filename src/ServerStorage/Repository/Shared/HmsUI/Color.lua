local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")

local Color = {
	Red = {
		[50] = Color3.fromRGB(255, 235, 238);
		[100] = Color3.fromRGB(255, 205, 210);
		[200] = Color3.fromRGB(239, 154, 154);
		[300] = Color3.fromRGB(229, 115, 115);
		[400] = Color3.fromRGB(239, 83, 80);
		[500] = Color3.fromRGB(244, 67, 54);
		[600] = Color3.fromRGB(229, 57, 53);
		[700] = Color3.fromRGB(211, 47, 47);
		[800] = Color3.fromRGB(198, 40, 40);
		[900] = Color3.fromRGB(183, 28, 28);

		Accent = {
			[100] = Color3.fromRGB(255, 138, 128);
			[200] = Color3.fromRGB(255, 82, 82);
			[400] = Color3.fromRGB(255, 23, 68);
			[700] = Color3.fromRGB(213, 0, 0);
		};
	};

	Pink = {
		[50] = Color3.fromRGB(252, 228, 236);
		[100] = Color3.fromRGB(248, 187, 208);
		[200] = Color3.fromRGB(244, 143, 177);
		[300] = Color3.fromRGB(240, 98, 146);
		[400] = Color3.fromRGB(236, 64, 122);
		[500] = Color3.fromRGB(233, 30, 99);
		[600] = Color3.fromRGB(216, 27, 96);
		[700] = Color3.fromRGB(194, 24, 91);
		[800] = Color3.fromRGB(173, 20, 87);
		[900] = Color3.fromRGB(136, 14, 79);

		Accent = {
			[100] = Color3.fromRGB(255, 128, 171);
			[200] = Color3.fromRGB(255, 64, 129);
			[400] = Color3.fromRGB(245, 0, 87);
			[700] = Color3.fromRGB(197, 17, 98);
		};
	};

	Purple = {
		[50] = Color3.fromRGB(243, 229, 245);
		[100] = Color3.fromRGB(225, 190, 231);
		[200] = Color3.fromRGB(206, 147, 216);
		[300] = Color3.fromRGB(186, 104, 200);
		[400] = Color3.fromRGB(171, 71, 188);
		[500] = Color3.fromRGB(156, 39, 176);
		[600] = Color3.fromRGB(142, 36, 170);
		[700] = Color3.fromRGB(123, 31, 162);
		[800] = Color3.fromRGB(106, 27, 154);
		[900] = Color3.fromRGB(74, 20, 140);

		Accent = {
			[100] = Color3.fromRGB(234, 128, 252);
			[200] = Color3.fromRGB(224, 64, 251);
			[400] = Color3.fromRGB(213, 0, 249);
			[700] = Color3.fromRGB(170, 0, 255);
		};
	};

	DeepPurple = {
		[50] = Color3.fromRGB(237, 231, 246);
		[100] = Color3.fromRGB(209, 196, 233);
		[200] = Color3.fromRGB(179, 157, 219);
		[300] = Color3.fromRGB(149, 117, 205);
		[400] = Color3.fromRGB(126, 87, 194);
		[500] = Color3.fromRGB(103, 58, 183);
		[600] = Color3.fromRGB(94, 53, 177);
		[700] = Color3.fromRGB(81, 45, 168);
		[800] = Color3.fromRGB(69, 39, 160);
		[900] = Color3.fromRGB(49, 27, 146);

		Accent = {
			[100] = Color3.fromRGB(179, 136, 255);
			[200] = Color3.fromRGB(124, 77, 255);
			[400] = Color3.fromRGB(101, 31, 255);
			[700] = Color3.fromRGB(98, 0, 234);
		};
	};

	Indigo = {
		[50] = Color3.fromRGB(232, 234, 246);
		[100] = Color3.fromRGB(197, 202, 233);
		[200] = Color3.fromRGB(159, 168, 218);
		[300] = Color3.fromRGB(121, 134, 203);
		[400] = Color3.fromRGB(92, 107, 192);
		[500] = Color3.fromRGB(63, 81, 181);
		[600] = Color3.fromRGB(57, 73, 171);
		[700] = Color3.fromRGB(48, 63, 159);
		[800] = Color3.fromRGB(40, 53, 147);
		[900] = Color3.fromRGB(26, 35, 126);

		Accent = {
			[100] = Color3.fromRGB(140, 158, 255);
			[200] = Color3.fromRGB(83, 109, 254);
			[400] = Color3.fromRGB(61, 90, 254);
			[700] = Color3.fromRGB(48, 79, 254);
		};
	};

	Blue = {
		[50] = Color3.fromRGB(227, 242, 253);
		[100] = Color3.fromRGB(187, 222, 251);
		[200] = Color3.fromRGB(144, 202, 249);
		[300] = Color3.fromRGB(100, 181, 246);
		[400] = Color3.fromRGB(66, 165, 245);
		[500] = Color3.fromRGB(33, 150, 243);
		[600] = Color3.fromRGB(30, 136, 229);
		[700] = Color3.fromRGB(25, 118, 210);
		[800] = Color3.fromRGB(21, 101, 192);
		[900] = Color3.fromRGB(13, 71, 161);

		Accent = {
			[100] = Color3.fromRGB(130, 177, 255);
			[200] = Color3.fromRGB(68, 138, 255);
			[400] = Color3.fromRGB(41, 121, 255);
			[700] = Color3.fromRGB(41, 98, 255);
		};
	};

	LightBlue = {
		[50] = Color3.fromRGB(225, 245, 254);
		[100] = Color3.fromRGB(179, 229, 252);
		[200] = Color3.fromRGB(129, 212, 250);
		[300] = Color3.fromRGB(79, 195, 247);
		[400] = Color3.fromRGB(41, 182, 246);
		[500] = Color3.fromRGB(3, 169, 244);
		[600] = Color3.fromRGB(3, 155, 229);
		[700] = Color3.fromRGB(2, 136, 209);
		[800] = Color3.fromRGB(2, 119, 189);
		[900] = Color3.fromRGB(1, 87, 155);

		Accent = {
			[100] = Color3.fromRGB(128, 216, 255);
			[200] = Color3.fromRGB(64, 196, 255);
			[400] = Color3.fromRGB(0, 176, 255);
			[700] = Color3.fromRGB(0, 145, 234);
		};
	};

	Cyan = {
		[50] = Color3.fromRGB(224, 247, 250);
		[100] = Color3.fromRGB(178, 235, 242);
		[200] = Color3.fromRGB(128, 222, 234);
		[300] = Color3.fromRGB(77, 208, 225);
		[400] = Color3.fromRGB(38, 198, 218);
		[500] = Color3.fromRGB(0, 188, 212);
		[600] = Color3.fromRGB(0, 172, 193);
		[700] = Color3.fromRGB(0, 151, 167);
		[800] = Color3.fromRGB(0, 131, 143);
		[900] = Color3.fromRGB(0, 96, 100);

		Accent = {
			[100] = Color3.fromRGB(132, 255, 255);
			[200] = Color3.fromRGB(24, 255, 255);
			[400] = Color3.fromRGB(0, 229, 255);
			[700] = Color3.fromRGB(0, 184, 212);
		};
	};

	Teal = {
		[50] = Color3.fromRGB(224, 242, 241);
		[100] = Color3.fromRGB(178, 223, 219);
		[200] = Color3.fromRGB(128, 203, 196);
		[300] = Color3.fromRGB(77, 182, 172);
		[400] = Color3.fromRGB(38, 166, 154);
		[500] = Color3.fromRGB(0, 150, 136);
		[600] = Color3.fromRGB(0, 137, 123);
		[700] = Color3.fromRGB(0, 121, 107);
		[800] = Color3.fromRGB(0, 105, 92);
		[900] = Color3.fromRGB(0, 77, 64);

		Accent = {
			[100] = Color3.fromRGB(167, 255, 235);
			[200] = Color3.fromRGB(100, 255, 218);
			[400] = Color3.fromRGB(29, 233, 182);
			[700] = Color3.fromRGB(0, 191, 165);
		};
	};

	Green = {
		[50] = Color3.fromRGB(232, 245, 233);
		[100] = Color3.fromRGB(200, 230, 201);
		[200] = Color3.fromRGB(165, 214, 167);
		[300] = Color3.fromRGB(129, 199, 132);
		[400] = Color3.fromRGB(102, 187, 106);
		[500] = Color3.fromRGB(76, 175, 80);
		[600] = Color3.fromRGB(67, 160, 71);
		[700] = Color3.fromRGB(56, 142, 60);
		[800] = Color3.fromRGB(46, 125, 50);
		[900] = Color3.fromRGB(27, 94, 32);

		Accent = {
			[100] = Color3.fromRGB(185, 246, 202);
			[200] = Color3.fromRGB(105, 240, 174);
			[400] = Color3.fromRGB(0, 230, 118);
			[700] = Color3.fromRGB(0, 200, 83);
		};
	};

	LightGreen = {
		[50] = Color3.fromRGB(241, 248, 233);
		[100] = Color3.fromRGB(220, 237, 200);
		[200] = Color3.fromRGB(197, 225, 165);
		[300] = Color3.fromRGB(174, 213, 129);
		[400] = Color3.fromRGB(156, 204, 101);
		[500] = Color3.fromRGB(139, 195, 74);
		[600] = Color3.fromRGB(124, 179, 66);
		[700] = Color3.fromRGB(104, 159, 56);
		[800] = Color3.fromRGB(85, 139, 47);
		[900] = Color3.fromRGB(51, 105, 30);

		Accent = {
			[100] = Color3.fromRGB(204, 255, 144);
			[200] = Color3.fromRGB(178, 255, 89);
			[400] = Color3.fromRGB(118, 255, 3);
			[700] = Color3.fromRGB(100, 221, 23);
		};
	};

	Lime = {
		[50] = Color3.fromRGB(249, 251, 231);
		[100] = Color3.fromRGB(240, 244, 195);
		[200] = Color3.fromRGB(230, 238, 156);
		[300] = Color3.fromRGB(220, 231, 117);
		[400] = Color3.fromRGB(212, 225, 87);
		[500] = Color3.fromRGB(205, 220, 57);
		[600] = Color3.fromRGB(192, 202, 51);
		[700] = Color3.fromRGB(175, 180, 43);
		[800] = Color3.fromRGB(158, 157, 36);
		[900] = Color3.fromRGB(130, 119, 23);

		Accent = {
			[100] = Color3.fromRGB(244, 255, 129);
			[200] = Color3.fromRGB(238, 255, 65);
			[400] = Color3.fromRGB(198, 255, 0);
			[700] = Color3.fromRGB(174, 234, 0);
		};
	};

	Yellow = {
		[50] = Color3.fromRGB(255, 253, 231);
		[100] = Color3.fromRGB(255, 249, 196);
		[200] = Color3.fromRGB(255, 245, 157);
		[300] = Color3.fromRGB(255, 241, 118);
		[400] = Color3.fromRGB(255, 238, 88);
		[500] = Color3.fromRGB(255, 235, 59);
		[600] = Color3.fromRGB(253, 216, 53);
		[700] = Color3.fromRGB(251, 192, 45);
		[800] = Color3.fromRGB(249, 168, 37);
		[900] = Color3.fromRGB(245, 127, 23);

		Accent = {
			[100] = Color3.fromRGB(255, 255, 141);
			[200] = Color3.fromRGB(255, 255, 0);
			[400] = Color3.fromRGB(255, 234, 0);
			[700] = Color3.fromRGB(255, 214, 0);
		};
	};

	Amber = {
		[50] = Color3.fromRGB(255, 248, 225);
		[100] = Color3.fromRGB(255, 236, 179);
		[200] = Color3.fromRGB(255, 224, 130);
		[300] = Color3.fromRGB(255, 213, 79);
		[400] = Color3.fromRGB(255, 202, 40);
		[500] = Color3.fromRGB(255, 193, 7);
		[600] = Color3.fromRGB(255, 179, 0);
		[700] = Color3.fromRGB(255, 160, 0);
		[800] = Color3.fromRGB(255, 143, 0);
		[900] = Color3.fromRGB(255, 111, 0);

		Accent = {
			[100] = Color3.fromRGB(255, 229, 127);
			[200] = Color3.fromRGB(255, 215, 64);
			[400] = Color3.fromRGB(255, 196, 0);
			[700] = Color3.fromRGB(255, 171, 0);
		};
	};

	Orange = {
		[50] = Color3.fromRGB(255, 243, 224);
		[100] = Color3.fromRGB(255, 224, 178);
		[200] = Color3.fromRGB(255, 204, 128);
		[300] = Color3.fromRGB(255, 183, 77);
		[400] = Color3.fromRGB(255, 167, 38);
		[500] = Color3.fromRGB(255, 152, 0);
		[600] = Color3.fromRGB(251, 140, 0);
		[700] = Color3.fromRGB(245, 124, 0);
		[800] = Color3.fromRGB(239, 108, 0);
		[900] = Color3.fromRGB(230, 81, 0);

		Accent = {
			[100] = Color3.fromRGB(255, 209, 128);
			[200] = Color3.fromRGB(255, 171, 64);
			[400] = Color3.fromRGB(255, 145, 0);
			[700] = Color3.fromRGB(255, 109, 0);
		};
	};

	DeepOrange = {
		[50] = Color3.fromRGB(251, 233, 231);
		[100] = Color3.fromRGB(255, 204, 188);
		[200] = Color3.fromRGB(255, 171, 145);
		[300] = Color3.fromRGB(255, 138, 101);
		[400] = Color3.fromRGB(255, 112, 67);
		[500] = Color3.fromRGB(255, 87, 34);
		[600] = Color3.fromRGB(244, 81, 30);
		[700] = Color3.fromRGB(230, 74, 25);
		[800] = Color3.fromRGB(216, 67, 21);
		[900] = Color3.fromRGB(191, 54, 12);

		Accent = {
			[100] = Color3.fromRGB(255, 158, 128);
			[200] = Color3.fromRGB(255, 110, 64);
			[400] = Color3.fromRGB(255, 61, 0);
			[700] = Color3.fromRGB(221, 44, 0);
		};
	};

	Brown = {
		[50] = Color3.fromRGB(239, 235, 233);
		[100] = Color3.fromRGB(215, 204, 200);
		[200] = Color3.fromRGB(188, 170, 164);
		[300] = Color3.fromRGB(161, 136, 127);
		[400] = Color3.fromRGB(141, 110, 99);
		[500] = Color3.fromRGB(121, 85, 72);
		[600] = Color3.fromRGB(109, 76, 65);
		[700] = Color3.fromRGB(93, 64, 55);
		[800] = Color3.fromRGB(78, 52, 46);
		[900] = Color3.fromRGB(62, 39, 35);
	};

	Grey = {
		[50] = Color3.fromRGB(250, 250, 250);
		[100] = Color3.fromRGB(245, 245, 245);
		[200] = Color3.fromRGB(238, 238, 238);
		[300] = Color3.fromRGB(224, 224, 224);
		[400] = Color3.fromRGB(189, 189, 189);
		[500] = Color3.fromRGB(158, 158, 158);
		[600] = Color3.fromRGB(117, 117, 117);
		[700] = Color3.fromRGB(97, 97, 97);
		[800] = Color3.fromRGB(66, 66, 66);
		[900] = Color3.fromRGB(33, 33, 33);
	};

	BlueGrey = {
		[50] = Color3.fromRGB(236, 239, 241);
		[100] = Color3.fromRGB(207, 216, 220);
		[200] = Color3.fromRGB(176, 190, 197);
		[300] = Color3.fromRGB(144, 164, 174);
		[400] = Color3.fromRGB(120, 144, 156);
		[500] = Color3.fromRGB(96, 125, 139);
		[600] = Color3.fromRGB(84, 110, 122);
		[700] = Color3.fromRGB(69, 90, 100);
		[800] = Color3.fromRGB(55, 71, 79);
		[900] = Color3.fromRGB(38, 50, 56);
	};

	Black = Color3.new();
	White = Color3.fromRGB(255, 255, 255);
}

function Color.toRGBString(c, a)
	local r = c.R * 255 + 0.5
	local g = c.G * 255 + 0.5
	local b = c.B * 255 + 0.5

	if a then
		return string.format("rgba(%u, %u, %u, %u)", r, g, b, a * 255 + 0.5)
	else
		return string.format("Color3.fromRGB(%u, %u, %u)", r, g, b)
	end
end

Color.ToRGBString = Color.toRGBString

function Color.toHexString(c, a)
	local r = c.R * 255 + 0.5
	local g = c.G * 255 + 0.5
	local b = c.B * 255 + 0.5

	if a then
		return string.format("#%X%X%X%X", r, g, b, a * 255 + 0.5)
	else
		return string.format("#%X%X%X", r, g, b)
	end
end

Color.ToHexString = Color.toHexString

local Hash = string.byte("#")

function Color.fromHex(Hex)
	-- Converts a 3-digit or 6-digit hex color to RGB
	-- Takes in a string of the form: "#FFFFFF" or "#FFF" or a 6-digit hexadecimal number

	local Type = type(Hex)
	local Digits

	if Type == "string" then
		-- Remove # from beginning
		if string.byte(Hex) == Hash then
			Hex = string.sub(Hex, 2)
		end

		Digits = #Hex

		if Digits == 8 then -- We got some alpha :D
			return Color.fromHex(string.sub(Hex, 1, -3)), tonumber(Hex, 16) % 0x000100 / 255
		end

		Hex = tonumber(Hex, 16) -- Leverage Lua's base converter :D
	elseif Type == "number" then
		Digits = 6 -- Assume numbers are 6 digit hex numbers
	end

	if Digits == 6 then
		-- Isolate R as first digits 5 and 6, G as 3 and 4, B as 1 and 2

		local R = (Hex - Hex % 0x010000) / 0x010000
		Hex = Hex - R * 0x010000
		local G = (Hex - Hex % 0x000100) / 0x000100

		return Color3.fromRGB(R, G, Hex - G * 0x000100)
	elseif Digits == 3 then
		-- 3-digit to 6-digit conversion: 123 -> 112233
		-- Thus, we isolate each digits' value and multiply by 17

		local R = (Hex - Hex % 0x100) / 0x100
		Hex = Hex - R * 0x100
		local G = (Hex - Hex % 0x10) / 0x10

		return Color3.fromRGB(R * 0x11, G * 0x11, (Hex - G * 0x10) * 0x11)
	end
end

Color.FromHex = Color.fromHex

function Color.toHex(Color3)
	return math.floor(Color3.R * 0xFF + 0.5) * 0x010000 + math.floor(Color3.G * 0xFF + 0.5) * 0x000100 + math.floor(Color3.B * 0xFF + 0.5) * 0x000001
end

Color.ToHex = Color.toHex

return Table.Lock(Color, nil, script.Name)