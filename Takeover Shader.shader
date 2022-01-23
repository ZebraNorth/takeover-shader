/**
 * Takeover: replace one material with another, slowly spreading across your model.
 */
Shader "Zebra North/Takeover"
{
    Properties
    {
        // Main texture properties.
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        [HDR] _Color("Color", Color) = (1,1,1,1)
        [NoScaleOffset] _MetallicMap("Metallic Map", 2D) = "black" {}
        _Metallic("Metallic", Range(0,1)) = 0.0
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _SmoothnessSource("Smoothness Source: Metallic Alpha - Albedo Alpha", Range(0, 1)) = 0.0
        [NoScaleOffset][Normal] _NormalMap("Normal Map", 2D) = "bump" {}
        [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "black" {}
        [HDR] _EmissionTint("Emission Tint", Color) = (0, 0, 0, 1)

        // Takeover texture properties.
        _TakeoverTex("Takeover Albedo (RGB)", 2D) = "white" {}
        [HDR] _TakeoverColor("Takeover Color", Color) = (1,1,1,1)
        [NoScaleOffset] _TakeoverMetallicMap("Takeover Metallic Map", 2D) = "black" {}
        _TakeoverMetallic("Takeover Metallic", Range(0,1)) = 0.0
        _TakeoverGlossiness("Takeover Smoothness", Range(0, 1)) = 0.5
        _TakeoverSmoothnessSource("Takeover Smoothness Source: Metallic Alpha - Albedo Alpha", Range(0, 1)) = 0.0
        [NoScaleOffset] [Normal] _TakeoverNormalMap("Takeover Normal Map", 2D) = "bump" {}
        [NoScaleOffset] _TakeoverEmissionMap("Takeover Emission Map", 2D) = "black" {}
        [HDR] _TakeoverEmissionTint("Takeover Emission Tint", Color) = (0, 0, 0, 1)

        // Takeover progression properties.
        _NoiseScale ("Noise scale", Float) = 1.0
        _StartPosition("Start Position", Vector) = (0, 1.0, 0.5)
        _MaxRadius("Avatar Radius", Float) = 3.5
        _Thickness("Transition Thickness", Range(0.00001, 3)) = 1.0

        // Animation properties.
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

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_TakeoverTex;
            float3 objectSpacePosition;
        };

        // Main texture properties.
        sampler2D _MainTex;
        float4 _Color;
        sampler2D _MetallicMap;
        float _Metallic;
        float _Glossiness;
        float SmoothnessSource;
        sampler2D _NormalMap;
        sampler2D _EmissionMap;
        float3 _EmissionTint;

        // Takeover texture properties.
        sampler2D _TakeoverTex;
        float4 _TakeoverColor;
        sampler2D _TakeoverMetallicMap;
        float _TakeoverMetallic;
        float _TakeoverGlossiness;
        float _TakeoverSmoothnessSource;
        sampler2D _TakeoverNormalMap;
        sampler2D _TakeoverEmissionMap;
        float3 _TakeoverEmissionTint;

        // Takeover progression properties.
        float _SmoothnessSource;
        float _NoiseScale;
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

        /**
         * Vertex shader.
         *
         * @param appdata_full v See UnityCG.cginc.
         * @param Input        o The output to the surface shader.
         */
        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.objectSpacePosition = v.vertex;
        }

        /**
         * The surface shader.
         *
         * @param Input                 IN The output from the vertex shader.
         * @param SurfaceOutputStandard o  See UnityPBSLighting.cginc.
         */
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float radius = _Threshold * _MaxRadius;
            float d = distance(_StartPosition, IN.objectSpacePosition);
            float thickness = _Thickness;

            float fadeIn = smoothstep(radius - thickness, radius, d);
            float noise = (noise2d(IN.uv_MainTex * _NoiseScale) + 1.0) / 2.0;

            float mixture = step(fadeIn, noise);

            // Mix the original material with the takeover material.

            // Albedo.
            float4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            float4 tc = tex2D(_TakeoverTex, IN.uv_TakeoverTex) * _TakeoverColor;
            o.Albedo = lerp(o.Albedo, tc.rgb, mixture);

            // Metallic.
            float4 metallicMap = tex2D(_MetallicMap, IN.uv_MainTex);
            float4 takeoverMetallicMap = tex2D(_TakeoverMetallicMap, IN.uv_TakeoverTex);
            o.Metallic = lerp(metallicMap.r * _Metallic, takeoverMetallicMap.r * _TakeoverMetallic, mixture);

            // Smoothness.
            float smoothness = lerp(c.a, metallicMap.a, _SmoothnessSource);
            float takeoverSmoothness = lerp(tc.a, takeoverMetallicMap.a, _TakeoverSmoothnessSource);
            o.Smoothness = lerp(smoothness * _Glossiness, takeoverSmoothness * _TakeoverGlossiness, mixture);

            // Normal.
            o.Normal = normalize(lerp(UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex)), UnpackNormal(tex2D(_TakeoverNormalMap, IN.uv_TakeoverTex)), mixture));

            // Emission.
            o.Emission = lerp(tex2D(_EmissionMap, IN.uv_MainTex) * _EmissionTint, tex2D(_TakeoverEmissionMap, IN.uv_TakeoverTex) * _TakeoverEmissionTint, mixture);

            // Alpha.
            o.Alpha = lerp(c.a, tc.a, mixture);
        }
        ENDCG
    }

    FallBack "Diffuse"
}
