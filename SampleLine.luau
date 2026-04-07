--[[
	=======================================================
	  線形データ定義ファイル
	=======================================================

	■ 平面線形 (alignment.elements)
	  kanwa(半径, 角度, 緩和長)
	    → 緩和曲線付き本線カーブ（カントあり）

	  kanwaNokanto(半径, 角度, 緩和長)
	    → 緩和曲線付きカーブ（カントなし）

	  nokanwa(半径, 角度)
	    → 緩和なし曲線（ポイントなど）

	  line(長さ)
	    → 直線

	■ 縦断線形 (profile.elements)
	  grade(勾配_permil, 長さ)
	    → 勾配一定区間。勾配は ‰（パーミル）単位。
	      正 = 上り、負 = 下り、0 = 水平。

	  vcurve(開始勾配_permil, 終了勾配_permil, 長さ)
	    → 放物線縦曲線。
	      開始勾配から終了勾配へ、長さ分かけて滑らかに変化する。
	      長さを長くするほど緩やかな変化になる。

	  ※ profile を省略するとすべて高さ 0 の水平線形になります。
	  ※ profile の合計長さが alignment より短い場合、
	    不足分は最終勾配のまま延長されます（末端クランプ）。
	=======================================================
	
	
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。
	線形定義は140行目以降です。


--]]

--------------------------------------------------
-- 平面線形ヘルパー
--------------------------------------------------

local function kanwa(radius, totalAngle, kanwalength)
	local arc_angle = totalAngle - kanwalength / radius
	-- arc_angleが負になったら緩和が長すぎる
	assert(arc_angle > 0, "緩和長が長すぎます")
	return {
		{type="clothoid", length=kanwalength,  startRadius=math.huge, endRadius=radius},
		{type="arc",      radius=radius, angle=arc_angle, length=radius * arc_angle},
		{type="clothoid", length=kanwalength,  startRadius=radius,    endRadius=math.huge},
	}
end

local function kanwaNokanto(radius, totalAngle, kanwalength)
	local arc_angle = totalAngle - kanwalength / radius
	-- arc_angleが負になったら緩和が長すぎる
	assert(arc_angle > 0, "緩和長が長すぎます")
	return {
		{type="Nclothoid", length=kanwalength,  startRadius=math.huge, endRadius=radius},
		{type="Narc",      radius=radius, angle=arc_angle, length=radius * arc_angle},
		{type="Nclothoid", length=kanwalength,  startRadius=radius,    endRadius=math.huge},
	}
end

local function nokanwa(radius, angle)
	return {
		{type="Narc", radius=radius, angle=angle, length=radius * angle},
	}
end

local function line(length)
	return {
		{type="line", length=length},
	}
end

--------------------------------------------------
-- 縦断線形ヘルパー
--------------------------------------------------

-- 勾配一定区間
-- grade_permil : 勾配 [‰]  例) 10 → 10‰ 上り、-5 → 5‰ 下り、0 → 水平
-- length       : 区間長 [m]
local function grade(grade_permil, length)
	return {
		{type="grade", grade=grade_permil, length=length},
	}
end

-- 放物線縦曲線
-- startGrade_permil : 開始勾配 [‰]
-- endGrade_permil   : 終了勾配 [‰]
-- length            : 縦曲線長 [m]  ※ 長いほど変化が緩やか
local function vcurve(startGrade_permil, endGrade_permil, length)
	return {
		{type="vcurve", startGrade=startGrade_permil, endGrade=endGrade_permil, length=length},
	}
end

--------------------------------------------------
-- テーブル平坦化
--------------------------------------------------

local function flatten(list)
	local result = {}
	for _, v in ipairs(list) do
		if v.type then
			table.insert(result, v)
		else
			for _, e in ipairs(v) do
				table.insert(result, e)
			end
		end
	end
	return result
end

--------------------------------------------------
-- 線形データ定義
--------------------------------------------------

local railsA = {

	--------------------------------------------------
	-- 平面線形
	--------------------------------------------------
	alignment = {
		elements = flatten({
			line(200),
			kanwa(300, math.rad(30), 50),
			kanwa(-300, math.rad(30), 50),
			line(100),
			nokanwa(150, math.rad(30)),
			line(100),
		})
	},

	--------------------------------------------------
	-- 縦断線形
	--
	-- 例: 0‰ で水平走行 → 縦曲線で 10‰ まで加速 → 10‰ 上り坂
	--     → 縦曲線で 0‰ に戻る → 再び水平
	--
	-- ポイント:
	--   vcurve の長さを長くするほど勾配変化が緩やかになります。
	--   grade + vcurve の合計が alignment の全長と一致するのが理想ですが、
	--   短い場合は末端勾配で打ち切り、長い場合は余剰分を無視します。
	--------------------------------------------------
	profile = {
		elements = flatten({
			grade(  0,  100),      -- 水平 100m（alignment 先頭の直線に対応）
			vcurve( 0, 10,  80),   -- 0‰ → 10‰ 縦曲線 80m（緩和曲線付きカーブ入口）
			grade( 10, 100),       -- 10‰ 上り坂 100m
			vcurve(10,  0,  80),   -- 10‰ → 0‰ 縦曲線 80m（カーブ出口）
			grade(  0, 100),       -- 水平 100m
			vcurve( 0, -8,  60),   -- 0‰ → -8‰ 縦曲線 60m（下り始め）
			grade( -8, 100),       -- -8‰ 下り坂 100m
			vcurve(-8,  0,  60),   -- -8‰ → 0‰ 縦曲線 60m（水平に戻る）
			grade(  0, 100),       -- 水平 100m（末尾）
		})
	},

}

return railsA