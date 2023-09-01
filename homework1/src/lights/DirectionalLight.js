class DirectionalLight {

    constructor(lightIntensity, lightColor, lightPos, focalPoint, lightUp, hasShadowMap, gl) {
        this.mesh = Mesh.cube(setTransform(0, 0, 0, 0.2, 0.2, 0.2, 0));
        this.mat = new EmissiveMaterial(lightIntensity, lightColor);
        this.lightPos = lightPos;
        this.focalPoint = focalPoint;
        this.lightUp = lightUp

        this.hasShadowMap = hasShadowMap;
        this.fbo = new FBO(gl);
        if (!this.fbo) {
            console.log("无法设置帧缓冲区对象");
            return;
        }
    }

    CalcLightMVP(translate, scale) {
        let lightMVP = mat4.create();
        let modelMatrix = mat4.create();
        let viewMatrix = mat4.create();
        let projectionMatrix = mat4.create();

        // Model transform
        let modelTMatrix = mat4.create()
        let modelSMatrix = mat4.create()
        mat4.fromTranslation(modelTMatrix, translate)
        mat4.fromScaling(modelSMatrix, scale)
        mat4.multiply(modelMatrix, modelTMatrix, modelSMatrix)
        // mat4.translate(modelMatrix, modelMatrix, translate)
        // mat4.scale(modelMatrix, modelMatrix, scale)

        // View transform
        mat4.lookAt(viewMatrix, this.lightPos, this.focalPoint, this.lightUp)
    
        // Projection transform
        let left = -100;
        let right = 100;
        let bottom = -100;
        let top = 100;
        let near = 1;
        let far = 500;
        mat4.ortho(projectionMatrix, left, right, bottom, top, near, far)

        mat4.multiply(lightMVP, projectionMatrix, viewMatrix);
        mat4.multiply(lightMVP, lightMVP, modelMatrix);

        return lightMVP;
    }
}
