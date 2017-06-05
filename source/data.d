module data;

import batcher : Vertex, vec2f, vec3f, vec4f, VertexSlice;

struct Data
{
	enum State { Begin, Middle, End, }

	float x, y, z;
	long timestamp;
	State state;
}

//Id(12,  89)
auto id12_89 = [
	Data(2592.73,  29898.1, 0, 20000000, Data.State.Begin), 
	Data(4718.28,  30201.3, 0, 120000000, Data.State.Middle), 
	Data(7217.78,  31579.6, 0, 220000000, Data.State.Middle), 
	Data(8803.98,  31867.5, 0, 320000000, Data.State.Middle), 
	Data(10319.9,  32846.7, 0, 420000000, Data.State.Middle), 
	Data(12101.3,  33290.6, 0, 520000000, Data.State.Middle), 
	Data(  15099,    34126, 0, 620000000, Data.State.Middle), 
	Data(15750.3,  34418.7, 0, 720000000, Data.State.Middle), 
	Data(  18450,  35493.3, 0, 820000000, Data.State.Middle), 
	Data(20338.8,  36117.9, 0, 920000000, Data.State.Middle), 
	Data(22569.5,    36753, 0, 1020000000, Data.State.Middle), 
	Data(23030.3,  37399.1, 0, 1120000000, Data.State.Middle), 
	Data(26894.2,  38076.8, 0, 1220000000, Data.State.Middle), 
	Data(27829.2,  38624.7, 0, 1320000000, Data.State.Middle), 
	Data(30832.9,  39502.2, 0, 1420000000, Data.State.Middle), 
	Data(31785.5,  39910.8, 0, 1520000000, Data.State.Middle), 
	Data(34543.4,  39246.4, 0, 1620000000, Data.State.Middle), 
	Data(36346.9,  38694.4, 0, 1720000000, Data.State.Middle), 
	Data(38273.6,    38011, 0, 1820000000, Data.State.Middle), 
	Data(39485.8,    37357, 0, 1920000000, Data.State.Middle), 
	Data(  42242,  36425.5, 0, 2020000000, Data.State.Middle), 
	Data(43082.6,  36391.4, 0, 2120000000, Data.State.Middle), 
	Data(47068.2,  34976.8, 0, 2220000000, Data.State.Middle), 
	Data(48361.4,  34596.8, 0, 2320000000, Data.State.Middle), 
	Data(50459.5,  34002.1, 0, 2420000000, Data.State.Middle), 
	Data(53024.4,  33244.2, 0, 2520000000, Data.State.Middle), 
	Data(54822.9,  32615.2, 0, 2620000000, Data.State.Middle), 
	Data(56916.5,    31945, 0, 2720000000, Data.State.Middle), 
	Data(59601.7,  31186.4, 0, 2820000000, Data.State.End),
];

import std.math : PI;

auto v12_89 = [
	Vertex(vec3f(2592.73,  29898.1, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(  0 * PI/180.0, 0)), 
	Vertex(vec3f(4718.28,  30201.3, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f( 30 * PI/180.0, 0)), 
	Vertex(vec3f(7217.78,  31579.6, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f( 60 * PI/180.0, 0)), 
	Vertex(vec3f(8803.98,  31867.5, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f( 90 * PI/180.0, 0)), 
	Vertex(vec3f(10319.9,  32846.7, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(120 * PI/180.0, 0)), 
	Vertex(vec3f(12101.3,  33290.6, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(150 * PI/180.0, 0)), 
	Vertex(vec3f(  15099,    34126, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(180 * PI/180.0, 0)), 
	Vertex(vec3f(15750.3,  34418.7, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(  18450,  35493.3, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(20338.8,  36117.9, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(22569.5,    36753, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(23030.3,  37399.1, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(26894.2,  38076.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(27829.2,  38624.7, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(30832.9,  39502.2, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(31785.5,  39910.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(34543.4,  39246.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(36346.9,  38694.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(38273.6,    38011, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(39485.8,    37357, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(  42242,  36425.5, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(43082.6,  36391.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(47068.2,  34976.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(48361.4,  34596.8, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(50459.5,  34002.1, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(53024.4,  33244.2, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(54822.9,  32615.2, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(56916.5,    31945, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)), 
	Vertex(vec3f(59601.7,  31186.4, 0), vec4f(1.0, 1.0, 1.0, 1.0), vec2f(1.0, 0)),
];

auto vs12_89_line = [
	//VertexSlice(VertexSlice.Kind.LineStrip, 0, 28),
	VertexSlice(VertexSlice.Kind.LineStrip, 0, 28),
];

auto vs12_89_point = [
	//VertexSlice(VertexSlice.Kind.LineStrip, 0, 28),
	VertexSlice(VertexSlice.Kind.Points, 0, 28),
];

//Id( 1, 126)
auto id1_126 = [
	Data(3135.29,  668.659, 0, 10000000, Data.State.Begin), 
	Data( 4860.4, -85.6403, 0, 110000000, Data.State.Middle), 
	Data(7485.96, -190.656, 0, 210000000, Data.State.Middle), 
	Data(9361.67,   2587.7, 0, 310000000, Data.State.Middle), 
	Data(10817.4,  2053.81, 0, 410000000, Data.State.Middle), 
	Data(12390.7,  2317.39, 0, 510000000, Data.State.Middle), 
	Data(15186.9,  4456.81, 0, 610000000, Data.State.Middle), 
	Data(  15811,  4352.42, 0, 710000000, Data.State.Middle), 
	Data(18040.1,  4411.44, 0, 810000000, Data.State.Middle), 
	Data(20886.9,  4700.86, 0, 910000000, Data.State.Middle), 
	Data(22232.5,  6572.29, 0, 1010000000, Data.State.Middle), 
	Data(23841.5,     7520, 0, 1110000000, Data.State.Middle), 
	Data(25883.6,  8127.31, 0, 1210000000, Data.State.Middle), 
	Data(  27827,  9057.05, 0, 1310000000, Data.State.Middle), 
	Data(29128.5,  9154.44, 0, 1410000000, Data.State.Middle), 
	Data(31602.9,   9282.4, 0, 1510000000, Data.State.Middle), 
	Data(33973.6,  8615.77, 0, 1610000000, Data.State.Middle), 
	Data(37100.9,  8723.32, 0, 1710000000, Data.State.Middle), 
	Data(38716.1,  8272.56, 0, 1810000000, Data.State.Middle), 
	Data(40968.5,  6778.36, 0, 1910000000, Data.State.Middle), 
	Data(41736.1,   6818.2, 0, 2010000000, Data.State.Middle), 
	Data(44605.6,  6152.04, 0, 2110000000, Data.State.Middle), 
	Data(46346.3,  5509.49, 0, 2210000000, Data.State.Middle), 
	Data(47749.2,  4449.36, 0, 2310000000, Data.State.Middle), 
	Data(50347.4,  3547.09, 0, 2410000000, Data.State.Middle), 
	Data(52208.5,  2735.65, 0, 2510000000, Data.State.Middle), 
	Data(54349.9,  2661.61, 0, 2610000000, Data.State.Middle), 
	Data(57004.1,  2121.54, 0, 2710000000, Data.State.Middle), 
	Data(58742.9,  849.437, 0, 2810000000, Data.State.End), 
];