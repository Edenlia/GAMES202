class PRTMaterial extends Material {

    constructor(light, vertexShader, fragmentShader) {
        super({
            'uPrecomputeLSH0': { type: '3fv', value: light[0] },
            'uPrecomputeLSH1': { type: '3fv', value: light[1] },
            'uPrecomputeLSH2': { type: '3fv', value: light[2] },
            'uPrecomputeLSH3': { type: '3fv', value: light[3] },
            'uPrecomputeLSH4': { type: '3fv', value: light[4] },
            'uPrecomputeLSH5': { type: '3fv', value: light[5] },
            'uPrecomputeLSH6': { type: '3fv', value: light[6] },
            'uPrecomputeLSH7': { type: '3fv', value: light[7] },
            'uPrecomputeLSH8': { type: '3fv', value: light[8] },
        }, [
            'aPrecomputeLT',
        ], vertexShader, fragmentShader, null);
    }
}

async function buildPRTMaterial(light, vertexPath, fragmentPath) {

    console.log(light);

    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PRTMaterial(light, vertexShader, fragmentShader);

}