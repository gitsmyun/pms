// 루트는 빌드 산출물 만들 목적이 아니라 "모노레포 Gradle 루트" 역할
tasks.register("hello") {
    doLast { println("pms monorepo root") }
}