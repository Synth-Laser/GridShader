Shader "Unlit/Grid"
{
    Properties
    {
        [Header(Aesthetics)]
        [Space()]

        _MainTex
            ("Texture", 2D)
            = "white" {}

        [HDR]_GridColour
            ("Grid Colour", Color)
            = (.255, .0, .0, 1)

        [Header(Size Configurations)]
        [Space()]

        _GridSizeX
            ("Grid Size X", Range(0.01, 1.0))
            = 0.1
            
        _GridSizeY
            ("Grid Size Y", Range(0.01, 1.0))
            = 0.1

        _GridLineThickness
            ("Grid Line Thickness", Range(0.00001, 0.010))
            = 0.003

        [Header(Transparency)]
        [Space()]

        _Alpha
            ("Grid Transparency", Range(0, 1))
            = 1.0

        _BGAlpha
            ("BG Transparency", Range(0, 1))
            = 0.0
    }
    SubShader
    {
        Tags  {"Queue" = "Transparent" "RenderType" = "Transparent" } 
        LOD 100
        Zwrite off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct vert2frag
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _GridColour;

            float _GridSizeX;
            float _GridSizeY;
            
            float _GridLineThickness;

            float _Alpha;
            float _BGAlpha;

            vert2frag vert (appdata vertInput)
            {
                vert2frag v2fOutput;
                
                v2fOutput.vertex = UnityObjectToClipPos(vertInput.vertex);
                v2fOutput.uv = TRANSFORM_TEX(vertInput.uv, _MainTex);
                UNITY_TRANSFER_FOG(v2fOutput, v2fOutput.vertex);

                return v2fOutput;
            }

            float GridTest(float2 uvNormalizedCoords)
            {
                float result;

                //grid spacing X
                for (float cell = 0.0; cell <= 1; cell += _GridSizeX)
                {
                    float currentCoordinate = uvNormalizedCoords.x - cell;
                    float isNotOnLine = smoothstep(0.0, _GridLineThickness, abs(currentCoordinate));
                    float isOnLine = 1.0 - isNotOnLine;

                    result += isOnLine;
                }
                //grid spacing Y
                for (float cell = 0.0; cell <= 1; cell += _GridSizeY)
                {
                    float currentCoordinate = uvNormalizedCoords.y - cell;
                    float isNotOnLine = smoothstep(0.0, _GridLineThickness, abs(currentCoordinate));
                    float isOnLine = 1.0 - isNotOnLine;

                    result += isOnLine;
                }

                return result;
            }

            fixed4 frag(vert2frag input) : SV_Target
            {
                float gridAmount = GridTest(input.uv);
                fixed4 textureColor = tex2D(_MainTex, input.uv);

                fixed4 gridColour = (_GridColour * gridAmount) + textureColor;

                gridColour.a = lerp(_BGAlpha, _Alpha, gridAmount);

                return float4(gridColour);
            }
            ENDCG
        }
    }
}
