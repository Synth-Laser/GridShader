Shader "Unlit/Grid"
{
    Properties
    {
        [Header(Colors)]
        [Space()]

        _MainTex
            ("Texture", 2D)
            = "clear" {}
            
        [Toggle()] _FilledLine
            ("Fill line with color", float)
            = 0

        [HDR]_GridColour
            ("Grid Colour", Color)
            = (.255, .0, .0, 1)

        [HDR]_BackgroundColour
            ("Background Colour", Color)
            = (.255, .0, .0, 1)

        [Header(Grid Configurations)]
        [Space()]
            
        _GridRows
            ("Grid Rows", Range(0.9, 100))
            = 2

        _GridColumns
            ("Grid Columns", Range(0.9, 100))
            = 1
            
        _OffsetX
            ("Grid Offset X", Range(0.0, 1))
            = 0
        _OffsetY
            ("Grid Offset Y", Range(0.0, 1))
            = 0

        [Header(Line Configurations)]
        [Space()]

        _GridLineThickness
            ("Grid Line Thickness", Range(0.00001, 0.1))
            = 0.003

        [Toggle()] _SharpLine
            ("Use sharp lines", float)
            = 0
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
            float _FilledLine;
            float4 _BackgroundColour;

            float _GridRows;
            float _GridColumns;

            float _OffsetX;
            float _OffsetY;
            
            float _GridLineThickness;
            float _SharpLine;

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
                float result = 0.0;
                float gridSizeX = 1 / _GridColumns;
                float gridSizeY = 1 / _GridRows;

                //grid spacing X
                for (float cell = _OffsetX % gridSizeX; cell <= 1; cell += gridSizeX)
                {
                    float currentCoordinate = uvNormalizedCoords.x - cell;

                    float isNotOnLine = 
                    _SharpLine ?
                        step(_GridLineThickness, abs(currentCoordinate))
                    :
                        smoothstep(0.0, _GridLineThickness, abs(currentCoordinate))
                    ;

                    float isOnLine = 1.0 - isNotOnLine;

                    result += isOnLine;
                }
                //grid spacing Y
                for (float cell = _OffsetY % gridSizeY; cell <= 1; cell += gridSizeY)
                {
                    float currentCoordinate = uvNormalizedCoords.y - cell;
                    
                    float isNotOnLine = 
                    _SharpLine ?
                        step(_GridLineThickness, abs(currentCoordinate))
                    :
                        smoothstep(0.0, _GridLineThickness, abs(currentCoordinate))
                    ;

                    float isOnLine = 1.0 - isNotOnLine;

                    result += isOnLine;
                }

                if (result > 1) result = 1;
                return result;
            }

            fixed4 frag(vert2frag input) : SV_Target
            {
                //texture sample
                fixed4 textureColor = tex2D(_MainTex, input.uv);

                //fill base
                fixed4 fillColour = 
                _FilledLine ?
                    fixed4(0, 0, 0, 1)
                :
                    fixed4(1, 1, 1, 1)
                ;

                //bottom layer
                fillColour = lerp(fillColour, textureColor, textureColor.a);
                
                //grid mask
                float gridAmount = GridTest(input.uv);
                
                fixed4 gridColour = (_GridColour * gridAmount);
                gridColour += fillColour;
                gridColour.a = lerp(0, _GridColour.a, gridAmount);


                fixed4 bgColor = _BackgroundColour;
                bgColor.a = _BackgroundColour.a;

                fixed4 combinedColour = lerp(bgColor, gridColour, gridColour.a);

                return float4(combinedColour);
            }
            ENDCG
        }
    }
}
