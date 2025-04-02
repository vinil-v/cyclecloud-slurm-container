# Running Container Workloads in CycleCloud-Slurm – Multi-Node, Multi-GPU Jobs (NCCL Benchmark)

## Introduction
Microsoft Azure CycleCloud provides a powerful orchestration platform for deploying and managing HPC and AI workloads in the cloud. When combined with Slurm, it offers a flexible and scalable environment for running containerized applications on high-performance computing (HPC) clusters.

This guide explores how to run multi-node, multi-GPU workloads using containerized environments in a CycleCloud-Slurm cluster. It covers essential configurations, job submission strategies, and best practices for maximizing GPU utilization across multiple nodes.

## Why Use Containers in CycleCloud-Slurm?
Containers offer several advantages in an HPC and AI environment:
- **Portability**: Easily package applications with dependencies for consistent execution across different environments.
- **Isolation**: Prevent conflicts between different applications by running them in separate environments.
- **Reproducibility**: Ensure experiments and workloads run identically across different job submissions.
- **Scalability**: Leverage CycleCloud and Slurm to scale containerized workloads dynamically across multiple nodes and GPUs.

## Testing Scenario
Before running multi-node, multi-GPU NCCL jobs with containers in CycleCloud-Slurm, ensure the following:
- CycleCloud 8.x should be configured and running.
- Use **Standard_ND96asr_v4** VMs with NVIDIA GPUs and InfiniBand network.
- Slurm version **24.05.4-2** (cyclecloud-slurm **3.0.11**).
- Ubuntu **22.04** OS (**microsoft-dsvm:ubuntu-hpc:2204:latest** image containing GPU drivers, InfiniBand support, and essential HPC tools).
- **cyclecloud-slurm-container** project configured for Enroot and Pyxis.
- **Azure NHC Container** (Node Health Check Container) for running NCCL benchmarks.

## Setting Up the cyclecloud-slurm-container Project

### 1. Clone the Repository
```bash
git clone https://github.com/vinil-v/cyclecloud-slurm-container.git
```

### 2. Upload the Project to CycleCloud Locker
```bash
cd cyclecloud-slurm-container/
cyclecloud project upload <locker-name>
```

### 3. Configure the Project
The project sets up Pyxis and Enroot for running container workloads in Slurm. It includes configuration scripts for both the scheduler and compute nodes.

Verify directory structure:
```bash
ls specs/
# Output:
# default  execute  scheduler

ls specs/execute/cluster-init/scripts/
# Output:
# 000_nvme-setup.sh  001_enroot-setup.sh  002_pyxis-setup-execute.sh  README.txt

ls specs/scheduler/cluster-init/scripts/
# Output:
# 000_pyxis-setup-scheduler.sh  README.txt
```

## Configuring cyclecloud-slurm-container in CycleCloud Portal

1. **Login to CycleCloud Web Portal**
2. **Create a Slurm cluster** and select **Standard_ND96asr_v4** as the HPC VM type.
3. **Select Ubuntu 22.04 LTS** (microsoft-dsvm:ubuntu-hpc:2204:latest) in advanced settings.
4. **Add cyclecloud-slurm-container as a cluster-init project**:
   - **Scheduler cluster-init**: Select the `scheduler` directory.
   - **Execute cluster-init**: Select the `execute` directory.
5. **Save and start the cluster.**

## Running NCCL Benchmark Job

### 1. Create the Job Script (nccl_benchmark_job.sh)
```bash
#!/bin/bash
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=12
#SBATCH --gpus-per-node=8
#SBATCH --exclusive
#SBATCH -o nccl_allreduce_%j.log

export LD_LIBRARY_PATH=/usr/local/nccl-rdma-sharp-plugins/lib:/opt/openmpi/lib:$LD_LIBRARY_PATH \
       OMPI_MCA_coll_hcoll_enable=0 \
       NCCL_IB_PCI_RELAXED_ORDERING=1 \
       CUDA_DEVICE_ORDER=PCI_BUS_ID \
       NCCL_SOCKET_IFNAME=eth0 \
       NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml \
       NCCL_DEBUG=WARN \
       NCCL_MIN_NCHANNELS=32

CONT="mcr.microsoft.com#aznhc/aznhc-nv:latest"
PIN_MASK='ffffff000000,ffffff000000,ffffff,ffffff,ffffff000000000000000000,ffffff000000000000000000,ffffff000000000000,ffffff000000000000'
MOUNT="/opt/microsoft:/opt/microsoft"

srun --mpi=pmix \
     --cpu-bind=mask_cpu:$PIN_MASK \
     --container-image "${CONT}" \
     --container-mounts "${MOUNT}" \
     --ntasks-per-node=8 \
     --cpus-per-task=12 \
     --gpus-per-node=8 \
     --mem=0 \
     bash -c 'export LD_LIBRARY_PATH="/opt/openmpi/lib:$LD_LIBRARY_PATH"; /opt/nccl-tests/build/all_reduce_perf -b 1K -e 16G -f 2 -g 1 -c 0'
```

### 2. Submit the Job
```bash
sbatch -N 4 --gres=gpu:8 -p hpc ./nccl_benchmark_job.sh
```

### 3. Check the Job Status
```bash
squeue
```

### 4. Verify the Benchmark Results
After the job completes, check the log file:
```bash
cat nccl_allreduce_<jobid>.log
```
Expected output includes NCCL benchmark results showing GPU utilization across multiple nodes.

## Conclusion
By using Enroot and Pyxis in a CycleCloud-Slurm cluster, multi-node, multi-GPU workloads can efficiently run inside containers. This setup ensures portability, scalability, and optimal GPU utilization in an HPC environment.


 
