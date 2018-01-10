module track_layer;

import gfm.math : vec2f, seg2f;
import track_layer_render : TrackLayerRender;

bool intersection()(auto ref const(seg2f) s1, auto ref const(seg2f) s2, out vec2f intersection)
{
	auto a1 = s1.a.y - s1.b.y;
	auto b1 = s1.b.x - s1.a.x;
	auto c1 = s1.a.x*s1.b.y - s1.b.x*s1.a.y;

	auto a2 = s2.a.y - s2.b.y;
	auto b2 = s2.b.x - s2.a.x;
	auto c2 = s2.a.x*s2.b.y - s2.b.x*s2.a.y;

	auto d = a1*b2-a2*b1;

	import std.algorithm : max;
	if (d < float.epsilon*max(a1, a2, b1, b2))
		return false;

	intersection.x =  (b1*c2-b2*c1)/d;
	intersection.y = -(a1*c2-a2*c1)/d;

	return true;
}

struct TrackId
{
	uint source, number;
}

struct Report
{
	import std.datetime : SysTime;
	import gfm.math : vec3f;

	TrackId id;
	float heading;
	vec3f coord;
	SysTime timestamp;
}

class TrackLayer : TrackLayerRender
{
	import gfm.opengl : OpenGL;

	@property tracks() const { return _tracks; }

	void add(TrackId id, Report[] data)
	{
		_tracks[id.number] = data;
	}

	void build(OpenGL gl)
	{
		import std.algorithm : map;
		import std.array : array;
		import std.range : iota;
		import std.conv : castFrom;
		import track_layer_render : Vertex;
		import vertex_data : VertexSlice;

		Vertex[] vertices;
		uint[] indices;
		VertexSlice[] lines, points;

		auto reportToVertex(ref const(Report) r)
		{
			import track_layer_render : Vertex;
			import gfm.math : vec4f;

			Vertex v = void;
			
			v.position = r.coord;
			v.color = vec4f(1, 1, 1, 1);
			v.heading = r.heading;
			v.source = r.id.source;
			v.number = r.id.number;
			v.timestamp_hi = (r.timestamp.stdTime >> 32) & 0xFFFFFFFF;
			v.timestamp_lo =       (r.timestamp.stdTime) & 0xFFFFFFFF;

			return v;
		}

		foreach(t; tracks.byValue)
		{
			auto v = t.map!reportToVertex.array;
			uint start  = castFrom!size_t.to!uint(vertices.length);
			uint finish = castFrom!size_t.to!uint(vertices.length + v.length);
			vertices ~= v;
			lines ~= VertexSlice(VertexSlice.Kind.LineStripAdjacency, cast(uint)(indices.length), finish - start + 2);
			points ~= VertexSlice(VertexSlice.Kind.Points, cast(uint)(indices.length) + 1, finish - start);

			indices.reserve(finish - start + 2);
			indices ~= [start] ~ iota(start, finish).array ~ [cast(uint)(finish - 1)];
		}

		setData(gl, vertices, indices, lines, points);
	}

	auto search(vec2f p, float distance)
	{
		import gfm.math : vec3f;

		float nearest = float.max;
		const(Report)* result;

		foreach(pair; _tracks.byKeyValue)
		{
			auto number = pair.key;
			foreach(ref report; pair.value)
			{
				auto v = report.coord - vec3f(p, 0);
				if (v.squaredLength <= distance*distance &&
				    v.squaredLength < nearest)
				{
					result = &report;
					nearest = v.squaredLength;
				}
			}
		}
		return result;
	}

	protected:
		Report[][uint] _tracks;
}
