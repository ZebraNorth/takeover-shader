Shader "Zebra North/Takeover"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0

        [HDR] _TakeoverColor("Takeover Color", Color) = (1,1,1,1)
        _TakeoverTex("Takeover Albedo (RGB)", 2D) = "white" {}
        _TakeoverGlossiness("Takeover Smoothness", Range(0,1)) = 0.5
        _TakeoverMetallic("Takeover Metallic", Range(0,1)) = 0.0

        _NoiseScale ("Noise scale", Float) = 1.0
        _StartPosition("Start Position", Vector) = (0, 1.0, 0.5)
        _MaxRadius("Avatar Radius", Float) = 3.5
        _Thickness("Transition Thickness", Float) = 1.0

        _Threshold("Threshold", Range(0, 1)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        #include "noise.cginc"

        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _TakeoverTex;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_TakeoverTex;
            float3 objectSpacePosition;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        half _TakeoverGlossiness;
        half _TakeoverMetallic;
        fixed4 _TakeoverColor;
        float _NoiseScale;
        float3 _BorderColour;
        float _Threshold;
        float _MaxRadius;
        float3 _StartPosition;
        float _Thickness;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)


        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.objectSpacePosition = v.vertex;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Original material.
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            float radius = _Threshold * _MaxRadius;
            float d = distance(_StartPosition, IN.objectSpacePosition);
            float thickness = _Thickness;

            float fadeIn = 1.0 - smoothstep(radius - thickness, radius, d);
            float noise = (noise2d(IN.uv_MainTex * _NoiseScale) + 1.0) / 2.0;

            float mixture = step(fadeIn, noise);
            if (noise < fadeIn)
                mixture = 1.0; else mixture = 0.0;

            // Mix the original material with the takeover material.
            fixed4 tc = tex2D(_TakeoverTex, IN.uv_TakeoverTex) * _TakeoverColor;
            o.Albedo = lerp(o.Albedo, tc.rgb, mixture);
            o.Metallic = lerp(o.Metallic, _TakeoverMetallic, mixture);
            o.Smoothness = lerp(o.Smoothness, _TakeoverGlossiness, mixture);
            o.Alpha = lerp(o.Alpha, tc.a, mixture);
        }
        ENDCG
    }

    FallBack "Diffuse"
}
